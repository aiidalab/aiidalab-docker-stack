# docker-bake.hcl
variable "VERSION" {
  default = "2022.1001"
}

variable "PYTHON_VERSION" {
  default = "3.9.4"
}

variable "AIIDA_VERSION" {
  default = "2.0.0"
}

variable "JUPYTER_BASE_IMAGE" {
  default = "jupyter/minimal-notebook:python-${PYTHON_VERSION}"
}

variable "ORGANIZATION" {
  default = "aiidalab"
}

variable "REGISTRY" {
  default = "docker.io/"
}

variable "PLATFORMS" {
  default = ["linux/amd64", "linux/arm64"]
}

function "tags" {
  params = [image]
  result = [
    "${REGISTRY}${ORGANIZATION}/${image}:${VERSION}",
    "${REGISTRY}${ORGANIZATION}/${image}:python-${PYTHON_VERSION}",
    "${REGISTRY}${ORGANIZATION}/${image}:aiida-${AIIDA_VERSION}",
  ]
}

group "default" {
  targets = ["base", "base-with-services", "lab"]
}

target "base" {
  context = "stack/base"
  platforms = "${PLATFORMS}"
  tags    = tags("base")
  args = {
    "BASE"          = "${JUPYTER_BASE_IMAGE}"
    "AIIDA_VERSION" = "${AIIDA_VERSION}"
  }
}
target "base-with-services" {
  context = "stack/base-with-services"
  contexts = {
    base = "target:base"
  }
  platforms = "${PLATFORMS}"
  tags = tags("base-with-services")
  args = {
    "AIIDA_VERSION" = "${AIIDA_VERSION}"
  }
}
target "lab" {
  context = "stack/lab"
  contexts = {
    base = "target:base"
  }
  platforms = "${PLATFORMS}"
  tags = tags("lab")
  args = {
    "AIIDALAB_VERSION"      = "22.08.0"
    "AIIDALAB_HOME_VERSION" = "v22.08.0"
  }
}
