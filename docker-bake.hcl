# docker-bake.hcl
variable "VERSION" {
}

variable "PYTHON_VERSION" {
}

#variable "PYTHON_MINOR_VERSION" {
#  default = join(".", slice(split(".", "${PYTHON_VERSION}"), 0, 2))
#}

variable "PGSQL_VERSION" {
}

variable "AIIDA_VERSION" {
}

variable "AIIDALAB_VERSION" {
}

variable "AIIDALAB_HOME_VERSION" {
}

variable "JUPYTER_BASE_IMAGE" {
  default = "jupyter/minimal-notebook:python-${PYTHON_VERSION}"
}

variable "ORGANIZATION" {
  default = "aiidalab"
}

variable "REGISTRY" {
  default = "docker.io"
}

variable "PLATFORMS" {
  default = ["linux/amd64"]
}

variable "TARGETS" {
  default = ["base", "base-with-services", "lab", "full-stack"]
}

function "tags" {
  params = [image]
  result = [
    "${REGISTRY}/${ORGANIZATION}/${image}:${VERSION}",
  ]
}

# Get a Python version string without the patch version (e.g. "3.9.13" -> "3.9")
# Used to construct paths to Python site-packages folder.
function "get_python_minor_version" {
  params = [python_version]
  result = join(".", slice(split(".", "${python_version}"), 0, 2))
}

group "default" {
  targets = "${TARGETS}"
}

target "base-meta" {
  tags = tags("base")
}
target "base-with-services-meta" {
  tags = tags("base-with-services")
}
target "lab-meta" {
  tags = tags("lab")
}

target "full-stack-meta" {
  tags = tags("full-stack")
}

target "base" {
  inherits = ["base-meta"]
  context = "stack/base"
  platforms = "${PLATFORMS}"
  args = {
    "BASE"          = "${JUPYTER_BASE_IMAGE}"
    "AIIDA_VERSION" = "${AIIDA_VERSION}"
  }
}
target "base-with-services" {
  inherits = ["base-with-services-meta"]
  context = "stack/base-with-services"
  contexts = {
    base = "target:base"
  }
  platforms = "${PLATFORMS}"
  args = {
    "AIIDA_VERSION" = "${AIIDA_VERSION}"
    "PGSQL_VERSION" = "${PGSQL_VERSION}"
  }
}
target "lab" {
  inherits = ["lab-meta"]
  context = "stack/lab"
  contexts = {
    base = "target:base"
  }
  platforms = "${PLATFORMS}"
  args = {
    "AIIDALAB_VERSION"      = "${AIIDALAB_VERSION}"
    "AIIDALAB_HOME_VERSION" = "${AIIDALAB_HOME_VERSION}"
    "PYTHON_MINOR_VERSION" = get_python_minor_version("${PYTHON_VERSION}")
  }
}
target "full-stack" {
  inherits = ["full-stack-meta"]
  context = "stack/full-stack"
  contexts = {
    base-with-services = "target:base-with-services"
    lab        = "target:lab"
  }
  platforms = "${PLATFORMS}"
}
