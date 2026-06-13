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
// Force every plugin module to compile against SDK 36. Flutter plugins
// (e.g. file_picker → flutter_plugin_android_lifecycle) otherwise default to
// an older compileSdk and fail the AAR metadata check. Registered BEFORE the
// evaluationDependsOn block below so afterEvaluate is attached before any
// subproject is force-evaluated.
subprojects {
    afterEvaluate {
        extensions.findByType(com.android.build.gradle.BaseExtension::class.java)
            ?.apply { compileSdkVersion(36) }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
