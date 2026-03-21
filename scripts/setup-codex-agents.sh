#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_url="${AOZORASEARCH_CODEX_AGENT_SOURCE_URL:-https://github.com/VoltAgent/awesome-codex-subagents.git}"
cache_dir="${AOZORASEARCH_CODEX_AGENT_CACHE_DIR:-$repo_root/.codex/cache/awesome-codex-subagents}"
destination_dir="${AOZORASEARCH_CODEX_AGENT_DEST_DIR:-$repo_root/.codex/agents}"
manifest_path="$destination_dir/.aozorasearch-managed-agents"

managed_agent_paths=(
  "categories/01-core-development/api-designer.toml"
  "categories/01-core-development/backend-developer.toml"
  "categories/01-core-development/code-mapper.toml"
  "categories/01-core-development/frontend-developer.toml"
  "categories/01-core-development/fullstack-developer.toml"
  "categories/01-core-development/ui-designer.toml"
  "categories/01-core-development/ui-fixer.toml"
  "categories/03-infrastructure/database-administrator.toml"
  "categories/03-infrastructure/deployment-engineer.toml"
  "categories/03-infrastructure/devops-engineer.toml"
  "categories/03-infrastructure/security-engineer.toml"
  "categories/03-infrastructure/sre-engineer.toml"
  "categories/04-quality-security/accessibility-tester.toml"
  "categories/04-quality-security/architect-reviewer.toml"
  "categories/04-quality-security/browser-debugger.toml"
  "categories/04-quality-security/code-reviewer.toml"
  "categories/04-quality-security/debugger.toml"
  "categories/04-quality-security/error-detective.toml"
  "categories/04-quality-security/performance-engineer.toml"
  "categories/04-quality-security/qa-expert.toml"
  "categories/04-quality-security/reviewer.toml"
  "categories/04-quality-security/security-auditor.toml"
  "categories/04-quality-security/test-automator.toml"
  "categories/06-developer-experience/build-engineer.toml"
  "categories/06-developer-experience/cli-developer.toml"
  "categories/06-developer-experience/dependency-manager.toml"
  "categories/06-developer-experience/documentation-engineer.toml"
  "categories/06-developer-experience/dx-optimizer.toml"
  "categories/06-developer-experience/git-workflow-manager.toml"
  "categories/06-developer-experience/legacy-modernizer.toml"
  "categories/06-developer-experience/refactoring-specialist.toml"
  "categories/06-developer-experience/tooling-engineer.toml"
  "categories/10-research-analysis/docs-researcher.toml"
  "categories/10-research-analysis/search-specialist.toml"
)

ensure_catalog() {
  mkdir -p "$(dirname "$cache_dir")"

  if [[ -d "$cache_dir/.git" ]]; then
    git -C "$cache_dir" pull --ff-only
    return
  fi

  if [[ -e "$cache_dir" ]]; then
    echo "Cache path exists but is not a git repository: $cache_dir" >&2
    exit 1
  fi

  git clone "$source_url" "$cache_dir"
}

managed_filename_lookup() {
  local filename="$1"
  local path
  for path in "${managed_agent_paths[@]}"; do
    if [[ "$(basename "$path")" == "$filename" ]]; then
      return 0
    fi
  done
  return 1
}

prune_removed_managed_agents() {
  if [[ ! -f "$manifest_path" ]]; then
    return 0
  fi

  local filename
  while IFS= read -r filename; do
    [[ -n "$filename" ]] || continue
    if ! managed_filename_lookup "$filename"; then
      rm -f "$destination_dir/$filename"
    fi
  done < "$manifest_path"
}

install_managed_agents() {
  mkdir -p "$destination_dir"
  prune_removed_managed_agents

  local installed_filenames=()
  local path
  local source_path
  local destination_path
  local filename

  for path in "${managed_agent_paths[@]}"; do
    source_path="$cache_dir/$path"
    filename="$(basename "$path")"
    destination_path="$destination_dir/$filename"

    if [[ ! -f "$source_path" ]]; then
      echo "Managed agent is missing from catalog: $path" >&2
      exit 1
    fi

    cp "$source_path" "$destination_path"
    installed_filenames+=("$filename")
  done

  printf '%s\n' "${installed_filenames[@]}" | sort > "$manifest_path"
  echo "Installed ${#installed_filenames[@]} managed agents into $destination_dir"
}

ensure_catalog
install_managed_agents
