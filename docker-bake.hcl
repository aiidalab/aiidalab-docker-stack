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

variable "PLATFORMS" {
  default = ["linux/amd64"]
}

variable "TARGETS" {
  default = ["base", "base-with-services", "lab", "full-stack"]
}

function "tags" {
  params = [image]
  result = [
    "${REGISTRY}${ORGANIZATION}/${image}:${VERSION}",
    "${REGISTRY}${ORGANIZATION}/${image}:python-${PYTHON_VERSION}",
    "${REGISTRY}${ORGANIZATION}/${image}:postgresql-${PGSQL_VERSION}",
    "${REGISTRY}${ORGANIZATION}/${image}:aiida-${AIIDA_VERSION}",
  ]
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

target "services" {
  context = "stack/services"
  platforms = "${PLATFORMS}"
  args = {
    "BASE"          = "${JUPYTER_BASE_IMAGE}"
    "AIIDA_VERSION" = "${AIIDA_VERSION}"
    "PGSQL_VERSION" = "${PGSQL_VERSION}"
  }
}

target "base-with-services" {
  inherits = ["base-with-services-meta"]
  context = "stack/base-with-services"
  contexts = {
    base = "target:base"
    services = "target:services"
  }
  platforms = "${PLATFORMS}"
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
  }
}
target "full-stack" {
  inherits = ["full-stack-meta"]
  context = "stack/full-stack"
  contexts = {
    services = "target:services"
    lab      = "target:lab"
  }
  platforms = "${PLATFORMS}"
}
