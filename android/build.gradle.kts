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
    val configureNamespace = Action<Project> {
        val manifestFile = file("src/main/AndroidManifest.xml")
        var pkgName: String? = null
        if (manifestFile.exists()) {
            try {
                var content = manifestFile.readText()
                if (content.contains("package=\"")) {
                    val pattern = java.util.regex.Pattern.compile("package=\"([^\"]+)\"")
                    val matcher = pattern.matcher(content)
                    if (matcher.find()) {
                        pkgName = matcher.group(1)
                    }
                    content = content.replace(Regex("package=\"[^\"]+\""), "")
                    manifestFile.writeText(content)
                }
            } catch (e: Exception) {
                // Ignore
            }
        }

        val androidExt = extensions.findByName("android")
        if (androidExt != null) {
            try {
                val getNamespaceMethod = androidExt.javaClass.getMethod("getNamespace")
                var namespaceVal = getNamespaceMethod.invoke(androidExt)
                if (namespaceVal == null) {
                    val namespaceMethod = androidExt.javaClass.getMethod("setNamespace", String::class.java)
                    val ns = pkgName ?: "ke.co.invois.invois_app.${name.replace("-", "_")}"
                    namespaceMethod.invoke(androidExt, ns)
                }
            } catch (e: Exception) {
                // Ignore
            }
        }
    }
    if (state.executed) {
        configureNamespace.execute(this)
    } else {
        afterEvaluate {
            configureNamespace.execute(this)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
