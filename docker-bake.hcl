variable "REGISTRY" {
    default = "docker.io"
}

variable "REGISTRY_USER" {
    default = "dvejmz"
}

variable "APP" {
    default = "oobabooga"
}

variable "RELEASE" {
    default = "1.20.0"
}

variable "CU_VERSION" {
    default = "121"
}

variable "BASE_IMAGE_REPOSITORY" {
    default = "ashleykza/runpod-base"
}

variable "BASE_IMAGE_VERSION" {
    default = "1.2.0"
}

variable "CUDA_VERSION" {
    default = "12.1.1"
}

variable "TORCH_VERSION" {
    default = "2.2.1"
}

target "default" {
    dockerfile = "Dockerfile"
    tags = ["${REGISTRY}/${REGISTRY_USER}/${APP}:${RELEASE}"]
    args = {
        RELEASE = "${RELEASE}"
        BASE_IMAGE = "${BASE_IMAGE_REPOSITORY}:${BASE_IMAGE_VERSION}-cuda${CUDA_VERSION}-torch${TORCH_VERSION}"
        INDEX_URL = "https://download.pytorch.org/whl/cu${CU_VERSION}"
        TORCH_VERSION = "${TORCH_VERSION}+cu${CU_VERSION}"
        OOBABOOGA_COMMIT = "9ac528715c54a65d9f5547a6c99c2ef1607204af"
        VENV_PATH = "/workspace/venvs/text-generation-webui"
    }
}
