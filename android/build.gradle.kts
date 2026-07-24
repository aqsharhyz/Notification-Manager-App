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
}

subprojects {
    val configureProject: () -> Unit = {
        if (plugins.hasPlugin("com.android.library")) {
            val android = extensions.findByName("android") as? com.android.build.gradle.LibraryExtension
            android?.apply {
                compileSdk = 34
                if (namespace == null) {
                    if (project.name == "notifications_listener_service") {
                        namespace = "kh.ad.notifications_listener_service"
                    } else {
                        namespace = "com.example.${project.name.replace("-", "_")}"
                    }
                }
            }
        }
    }

    if (state.executed) {
        configureProject()
    } else {
        afterEvaluate { configureProject() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

