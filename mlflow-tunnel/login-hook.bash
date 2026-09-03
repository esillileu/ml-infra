if [[ $- == *i* && -n ${SSH_CONNECTION:-} ]]; then
    if [[ -x ${HOME}/.local/bin/mlflow-tunnel ]]; then
        "${HOME}/.local/bin/mlflow-tunnel" status --active-only 2>/dev/null || true
    fi
fi
