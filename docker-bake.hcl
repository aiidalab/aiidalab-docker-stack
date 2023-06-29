# docker-bake.hcl
variable "VERSION" {
}

variable "PYTHON_VERSION" {
}

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
  default = "docker.io/"
}

variable "ARCH" {
  default = "amd64"
}

function "arch2platform" {
  params = [arch]
  result = "linux/${arch}"
}

variable "TARGETS" {
  default = ["base", "base-with-services", "lab", "full-stack"]
}

function "tags" {
  params = [image, arch]
  result = [
    "${REGISTRY}${ORGANIZATION}/${image}:${arch}-${VERSION}",
    "${REGISTRY}${ORGANIZATION}/${image}:${arch}-python-${PYTHON_VERSION}",
    "${REGISTRY}${ORGANIZATION}/${image}:${arch}-postgresql-${PGSQL_VERSION}",
    "${REGISTRY}${ORGANIZATION}/${image}:${arch}-aiida-${AIIDA_VERSION}",
    "${REGISTRY}${ORGANIZATION}/${image}:${arch}-newly-build",
  ]
}

group "default" {
  targets = "${TARGETS}"
}

target "base-meta" {
  tags = tags("base", "${ARCH}")
}
target "base-with-services-meta" {
  tags = tags("base-with-services", "${ARCH}")
}
target "lab-meta" {
  tags = tags("lab", "${ARCH}")
}

target "full-stack-meta" {
  tags = tags("full-stack", "${ARCH}")
}

target "base" {
  inherits = ["base-meta"]
  context = "stack/base"
  platforms = [arch2platform("${ARCH}")]
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
  platforms = [arch2platform("${ARCH}")]
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
  platforms = [arch2platform("${ARCH}")]
  args = {
    "AIIDALAB_VERSION"      = "${AIIDALAB_VERSION}"
    "AIIDALAB_HOME_VERSION" = "${AIIDALAB_HOME_VERSION}"
  }
}
target "full-stack" {
  inherits = ["full-stack-meta"]
  context = "stack/full-stack"
  contexts = {
    base-with-services = "target:base-with-services"
    lab        = "target:lab"
  }
  platforms = [arch2platform("${ARCH}")]
}
