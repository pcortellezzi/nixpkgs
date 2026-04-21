# Overlay to patch aquamarine for EVDI/DisplayLink compatibility
# This overlay should be applied AFTER the hyprland overlay if present
final: prev: {
  # Patch aquamarine if it exists (from hyprland overlay or nixpkgs)
  aquamarine = (prev.aquamarine or prev.aquamarine_0_10 or prev.aquamarine_0_9).overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/backend/drm/DRM.cpp \
        --replace-fail 'auto drmVerName = drmVer->name ? drmVer->name : "unknown";' \
          'auto drmVerName = drmVer->name ? drmVer->name : "unknown";
    // EVDI DEBUG
    bool isEvdi = std::string_view(drmVerName) == "evdi";
    backend->log(AQ_LOG_DEBUG, std::format("drm: EVDI-DEBUG: Device {} driver={} isEvdi={}", gpu->path, drmVerName, isEvdi ? "YES" : "NO"));' \
        --replace-fail '(primary ? std::format(" with primary {}", primary->gpu->path) : "")));' \
          '(primary ? std::format(" with primary {}", primary->gpu->path) : "")));
    // EVDI: Use card fd as render node fallback
    if (isEvdi && gpu_->renderNodeFd < 0) {
        backend->log(AQ_LOG_DEBUG, std::format("drm: EVDI: Setting renderNodeFd to fd for {}", gpu->path));
        gpu_->renderNodeFd = gpu_->fd;
    }' \
        --replace-fail 'drmFreeVersion(drmVer);' \
          'drmFreeVersion(drmVer);
    if (isEvdi) {
        backend->log(AQ_LOG_DEBUG, std::format("drm: EVDI: {} is EVDI, returning true", gpu->path));
        return true;
    }'
    '';
  });
}
