allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
    // Some Flutter plugins (e.g. flutter_native_splash) still resolve their
    // own compileSdk to 31, but their transitive AndroidX deps require >= 34.
    // Force every Android subproject to compile against 36. `:app` is already
    // evaluated here (evaluationDependsOn above), so set it directly and only
    // defer via afterEvaluate for the not-yet-evaluated plugin projects.
    val forceCompileSdk: () -> Unit = {
        extensions.findByName("android")?.withGroovyBuilder {
            "compileSdkVersion"(36)
        }
    }
    if (project.state.executed) {
        forceCompileSdk()
    } else {
        afterEvaluate { forceCompileSdk() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
