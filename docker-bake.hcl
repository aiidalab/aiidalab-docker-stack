# docker-bake.hcl
variable "VERSION" {
}

variable "PYTHON_VERSION" {
}

variable "PGSQL_VERSION" {
}

variable "RMQ_VERSION" {
}

variable "AIIDA_VERSION" {
}

variable "AIIDALAB_VERSION" {
}

variable "AWB_VERSION" {
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
    "${REGISTRY}${ORGANIZATION}/${image}${VERSION}",
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

target "base" {
  tags = tags("base")
  context = "stack/base"
  platforms = "${PLATFORMS}"
  args = {
    "BASE"          = "${JUPYTER_BASE_IMAGE}"
    "AIIDA_VERSION" = "${AIIDA_VERSION}"
  }
}
target "base-with-services" {
  tags = tags("base-with-services")
  context = "stack/base-with-services"
  contexts = {
    base = "target:base"
  }
  platforms = "${PLATFORMS}"
  args = {
    "AIIDA_VERSION" = "${AIIDA_VERSION}"
    "PGSQL_VERSION" = "${PGSQL_VERSION}"
    "RMQ_VERSION" = "${RMQ_VERSION}"
  }
}
target "lab" {
  tags = tags("lab")
  context = "stack/lab"
  contexts = {
    base = "target:base"
  }
  platforms = "${PLATFORMS}"
  args = {
    "AIIDALAB_VERSION"      = "${AIIDALAB_VERSION}"
    "AWB_VERSION"      = "${AWB_VERSION}"
    "AIIDALAB_HOME_VERSION" = "${AIIDALAB_HOME_VERSION}"
    "PYTHON_MINOR_VERSION" = get_python_minor_version("${PYTHON_VERSION}")
  }
}
target "full-stack" {
  tags = tags("full-stack")
  context = "stack/full-stack"
  contexts = {
    base-with-services = "target:base-with-services"
    lab        = "target:lab"
  }
  platforms = "${PLATFORMS}"
}
