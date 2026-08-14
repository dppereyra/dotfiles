update-podman-images() {
  podman image prune
  podman images --filter "dangling=false" --format "{{.Repository}}:{{.Tag}}" \
    | xargs -L1 podman pull
  podman image prune
}
