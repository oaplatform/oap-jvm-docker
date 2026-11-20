import java.net.URI
import javax.inject.Inject

plugins {
    base
}

/**
 * Latest apt version of java-<jvm>-amazon-corretto-jdk available for all requested platforms.
 */
abstract class LatestCorrettoVersion : ValueSource<String, LatestCorrettoVersion.Params> {
    interface Params : ValueSourceParameters {
        val jvmVersion: Property<String>
        val platforms: Property<String>
    }

    override fun obtain(): String {
        val pkg = "java-${parameters.jvmVersion.get()}-amazon-corretto-jdk"
        val archs = parameters.platforms.get().split(',').map { it.trim().substringAfterLast('/') }

        val common = archs
            .map { arch ->
                val index = URI("https://apt.corretto.aws/dists/stable/main/binary-$arch/Packages").toURL().readText()
                index.split(Regex("""\r?\n\r?\n"""))
                    .filter { entry -> entry.lineSequence().any { it.trim() == "Package: $pkg" } }
                    .mapNotNull { entry ->
                        entry.lineSequence().firstOrNull { it.startsWith("Version:") }?.substringAfter(':')?.trim()
                    }
                    .toSet()
            }
            .reduce { a, b -> a intersect b }

        return common.maxWithOrNull(::compareDebVersions)
            ?: error("$pkg not found on apt.corretto.aws for all of $archs")
    }

    private fun compareDebVersions(a: String, b: String): Int {
        fun parts(v: String): List<List<Int>> {
            val epoch = if (':' in v) v.substringBefore(':') else "0"
            val rest = v.substringAfter(':')
            val upstream = rest.substringBeforeLast('-')
            val revision = if ('-' in rest) rest.substringAfterLast('-') else "0"
            return listOf(epoch, upstream, revision).map { p -> p.split(Regex("""\D+""")).filter { it.isNotEmpty() }.map { it.toInt() } }
        }

        fun compareLists(x: List<Int>, y: List<Int>): Int {
            for (i in 0 until maxOf(x.size, y.size)) {
                val c = x.getOrElse(i) { -1 }.compareTo(y.getOrElse(i) { -1 })
                if (c != 0) return c
            }
            return 0
        }

        return parts(a).zip(parts(b)).map { (x, y) -> compareLists(x, y) }.firstOrNull { it != 0 } ?: 0
    }
}

abstract class DockerBuildx @Inject constructor(private val execOperations: ExecOperations) : DefaultTask() {
    @get:Input abstract val image: Property<String>
    @get:Input abstract val imageVersion: Property<String>
    @get:Input abstract val jvmVersion: Property<String>
    @get:Input abstract val correttoPackageVersion: Property<String>
    @get:Input abstract val platforms: Property<String>
    @get:Input abstract val push: Property<Boolean>
    @get:Internal abstract val contextDir: DirectoryProperty

    init {
        group = "docker"
    }

    @TaskAction
    fun build() {
        val packageVersion = correttoPackageVersion.get()
        // 1:25.0.5.1.2-1 -> 25.0.5.1.2
        val corretto = packageVersion.substringAfter(':').substringBeforeLast('-')
        val tag = "${image.get()}:$corretto-${imageVersion.get()}"

        println("##teamcity[buildNumber '$tag']")

        val args = mutableListOf(
            "docker", "buildx", "build",
            "--platform", platforms.get(),
            "--tag", tag,
            "--build-arg", "JVM_VERSION=${jvmVersion.get()}",
            "--build-arg", "CORRETTO_PACKAGE_VERSION=$packageVersion",
        )
        if (push.get()) args += "--push"
        args += "."

        execOperations.exec {
            workingDir = contextDir.get().asFile
            commandLine(args)
        }
    }
}

val oapJvmVersion = providers.gradleProperty("oap.jvm.version").get().also {
    require(it.matches(Regex("""\d+"""))) { "oap.jvm.version must be a major JDK version (e.g. 25), got '$it'" }
}
val dockerPlatforms = providers.gradleProperty("oap.docker.platforms")

val dockerRepository = providers.environmentVariable("REPOSITORY_URL")
    .filter { it.isNotBlank() }
    .orElse(providers.gradleProperty("oap.docker.repository"))
    .map { it.trim().removePrefix("https://").removePrefix("http://").trimEnd('/') }
val dockerImage = dockerRepository.zip(providers.gradleProperty("oap.docker.image")) { repository, image -> "$repository/$image" }

val oapCorrettoPackageVersion = providers.gradleProperty("oap.corretto.package.version")
    .orElse(providers.of(LatestCorrettoVersion::class) {
        parameters.jvmVersion = oapJvmVersion
        parameters.platforms = dockerPlatforms
    })

fun DockerBuildx.configure(push: Boolean) {
    image = dockerImage
    imageVersion = project.version.toString()
    jvmVersion = oapJvmVersion
    correttoPackageVersion = oapCorrettoPackageVersion
    platforms = dockerPlatforms
    this.push = push
    contextDir = layout.projectDirectory
}

val dockerBuild = tasks.register<DockerBuildx>("dockerBuild") {
    description = "Builds <repository>/<image>:<corretto>-<version> docker image"
    configure(push = false)
}

tasks.register<DockerBuildx>("dockerPush") {
    description = "Builds and pushes <repository>/<image>:<corretto>-<version> docker image"
    configure(push = true)
}

tasks.assemble {
    dependsOn(dockerBuild)
}
