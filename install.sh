\n" >&2
        info "If you would like to see a build for your configuration,"
        info "please create an issue requesting a build for ${MAGENTA}${target}${NO_COLOR}:"
        info "${BOLD}${UNDERLINE}https://github.com/hopinc/nixpacks/issues/new/${NO_COLOR}"
        printf "\n"
        exit 1
    fi
}
UNINSTALL=0
HELP=0
CARGOTOML="$(curl -fsSL https://raw.githubusercontent.com/hopinc/nixpacks/master/Cargo.toml)"
ALL_VERSIONS="$(sed -n 's/.*version = "\([^"]*\)".*/\1/p' <<< "$CARGOTOML")"
IFS=$'\n' read -r -a VERSION <<< "$ALL_VERSIONS"
DEFAULT_VERSION="$VERSION"

# defaults
if [ -z "${NIXPACKS_VERSION-}" ]; then
  NIXPACKS_VERSION="$DEFAULT_VERSION"
fi

if [ -z "${NIXPACKS_PLATFORM-}" ]; then
  PLATFORM="$(detect_platform)"
fi

if [ -z "${NIXPACKS_BIN_DIR-}" ]; then
  BIN_DIR=/usr/local/bin
fi

if [ -z "${NIXPACKS_ARCH-}" ]; then
  ARCH="$(detect_arch)"
fi

if [ -z "${BASE_URL-}" ]; then
  BASE_URL="https://github.com/hopinc/nixpacks/releases"
fi

# parse argv variables
while [ "$#" -gt 0 ]; do
  case "$1" in
  -p | --platform)
    PLATFORM="$2"
    shift 2
    ;;
  -b | --bin-dir)
    BIN_DIR="$2"
    shift 2
    ;;
  -a | --arch)
    ARCH="$2"
    shift 2
    ;;
  -B | --base-url)
    BASE_URL="$2"
    shift 2
    ;;

  -V | --verbose)
    VERBOSE=1
    shift 1
    ;;
  -f | -y | --force | --yes)
    FORCE=1
    shift 1
    ;;
  -r | --remove | --uninstall)
    UNINSTALL=1
    shift 1
    ;;
  -h | --help)
    HELP=1
    shift 1
    ;;
  -p=* | --platform=*)
    PLATFORM="${1#*=}"
    shift 1
    ;;
  -b=* | --bin-dir=*)
    BIN_DIR="${1#*=}"
    shift 1
    ;;
  -a=* | --arch=*)
    ARCH="${1#*=}"
    shift 1
    ;;
  -B=* | --base-url=*)
    BASE_URL="${1#*=}"
    shift 1
    ;;
  -V=* | --verbose=*)
    VERBOSE="${1#*=}"
    shift 1
    ;;
  -f=* | -y=* | --force=* | --yes=*)
    FORCE="${1#*=}"
    shift 1
    ;;

  *)
    error "Unknown option: $1"
    exit 1
    ;;
  esac
done

# non-empty VERBOSE enables verbose untarring
if [ -n "${VERBOSE-}" ]; then
  VERBOSE=v
else
  VERBOSE=
fi

if [ $UNINSTALL == 1 ]; then
  confirm "Are you sure you want to uninstall nixpacks?"

  msg=""
  sudo=""

  info "REMOVING nixpacks"

  if test_writeable "$(dirname "$(which nixpacks)")"; then
    sudo=""
    msg="Removing nixpacks, please wait…"
  else
    warn "Escalated permissions are required to install to ${BIN_DIR}"
    elevate_priv
    sudo="sudo"
    msg="Removing nixpacks as root, please wait…"
  fi

  info "$msg"
  ${sudo} rm "$(which nixpacks)"
  ${sudo} rm /tmp/nixpacks

  info "Removed nixpacks"
  exit 0

 fi
if [ $HELP == 1 ]; then
    echo "${help_text}"
    exit 0
fi
TARGET="$(detect_target "${ARCH}" "${PLATFORM}")"

is_build_available "${ARCH}" "${PLATFORM}" "${TARGET}"


print_configuration () {
  if [[ -n "${VERBOSE}" ]]; then
    printf "  %s\n" "${UNDERLINE}Configuration${NO_COLOR}"
    debug "${BOLD}Bin directory${NO_COLOR}: ${GREEN}${BIN_DIR}${NO_COLOR}"
    debug "${BOLD}Platform${NO_COLOR}:      ${GREEN}${PLATFORM}${NO_COLOR}"
    debug "${BOLD}Arch${NO_COLOR}:          ${GREEN}${ARCH}${NO_COLOR}"
    debug "${BOLD}Version${NO_COLOR}:       ${GREEN}${NIXPACKS_VERSION}${NO_COLOR}"
    printf '\n'
  fi
}

print_configuration


EXT=tar.gz
if [ "${PLATFORM}" = "pc-windows-msvc" ]; then
  EXT=zip
fi

URL="${BASE_URL}/download/v${NIXPACKS_VERSION}/nixpacks-v${NIXPACKS_VERSION}-${TARGET}.${EXT}"
debug "Tarball URL: ${UNDERLINE}${BLUE}${URL}${NO_COLOR}"
confirm "Install nixpacks ${GREEN}${NIXPACKS_VERSION}${NO_COLOR} to ${BOLD}${GREEN}${BIN_DIR}${NO_COLOR}?"
check_bin_dir "${BIN_DIR}"

install "${EXT}"

printf "$GREEN"
  cat <<'EOF'

      +--------------+
     /|             /|
    / |            / |
   *--+-----------*  |
   |  |           |  |                Nixpacks is now installed
   |  |           |  |             Run `nixpacks help` for commands
   |  |           |  |
   |  +-----------+--+
   | /            | /
   |/             |/
   *--------------*

EOF
printf "$NO_COLOR"
