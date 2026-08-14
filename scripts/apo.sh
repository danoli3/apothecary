#!/usr/bin/env bash
# apo.sh - apothecary CLI  |  Dan Rosser 2025
APO_SCRIPT_VERSION=0.3.0

APOTHECARY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APOTHECARY_DIR="$(realpath "$APOTHECARY_DIR/../")"
APOTHECARY_SCRIPTS="$(realpath "$APOTHECARY_DIR/scripts")"
APOTHECARY_PATH="$(realpath "$APOTHECARY_DIR/apothecary")"
FORMULAS_DIR="$(realpath "$APOTHECARY_PATH/formulas")"
APOTHECARY_BIN="$(realpath "$APOTHECARY_PATH/apothecary")"
# Honour pre-set paths (e.g. openFrameworks menu → libs/)
if [[ -z "${OUTPUT_FOLDER:-}" ]]; then
	mkdir -p "$APOTHECARY_DIR/out"
	OUTPUT_FOLDER="$(realpath "$APOTHECARY_DIR/out")"
else
	mkdir -p "$OUTPUT_FOLDER"
	OUTPUT_FOLDER="$(realpath "$OUTPUT_FOLDER")"
fi
if [[ -z "${BUILD_DIR:-}" ]]; then
	mkdir -p "$APOTHECARY_DIR/build"
	BUILD_DIR="$(realpath "$APOTHECARY_DIR/build")"
else
	mkdir -p "$BUILD_DIR"
	BUILD_DIR="$(realpath "$BUILD_DIR")"
fi

UI_APP_NAME="apothecary"
UI_APP_VERSION="$APO_SCRIPT_VERSION"
. "$APOTHECARY_SCRIPTS/ui.sh"

VALID_TYPES=(osx macos ios tvos xros watchos catos android linux vs msys2 emscripten)
FORCE="${FORCE:-${APO_FORCE:-0}}"
ACTION="${ACTION:-update}"

autoDetectHost(){
	export HOST_OS HOST_ARCH DEFAULT_TYPE TYPE ARCH
	HOST_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
	HOST_ARCH=$(uname -m)
	case "$HOST_OS" in
		darwin) HOST_OS="osx" ;;
		linux)  HOST_OS="linux" ;;
		mingw*|msys*|cygwin*) HOST_OS="msys2" ;;
	esac
	DEFAULT_TYPE="$HOST_OS"
	TYPE="${TYPE:-${TARGET:-$DEFAULT_TYPE}}"
	ARCH="${ARCH:-$HOST_ARCH}"
}

listFormulas(){
	local f name
	for f in "$FORMULAS_DIR"/*; do
		[[ -e "$f" ]] || continue
		name=$(basename "$f")
		[[ "$name" == _* ]] && continue
		if [[ -d "$f" ]]; then
			if [[ -f "$f/${name}.sh" ]] || [[ -f "$f/$(echo "$name" | tr '[:upper:]' '[:lower:]').sh" ]]; then
				printf '%s\n' "$name"
			elif ls "$f"/*.sh >/dev/null 2>&1; then
				printf '%s\n' "$name"
			fi
		elif [[ "$name" == *.sh ]]; then
			printf '%s\n' "${name%.sh}"
		fi
	done | sort -u
}

formulaCount(){
	listFormulas | wc -l | tr -d ' '
}

typeHasScripts(){
	local t="$1"
	[[ -d "${APOTHECARY_SCRIPTS}/${t}" ]]
}

archesForType(){
	local t="$1"
	case "$t" in
		osx|macos)  echo "arm64 x86_64" ;;
		ios|tvos|watchos|xros) echo "arm64 SIM_arm64 x86_64" ;;
		catos)      echo "arm64 x86_64" ;;
		android)    echo "arm64 armv7 x86 x86_64" ;;
		emscripten) echo "64 32" ;;
		linux)      echo "x86_64 arm64 aarch64 armv7l armv6l" ;;
		vs)         echo "64 arm64" ;;
		msys2)      echo "64" ;;
		*)          echo "$HOST_ARCH" ;;
	esac
}

autoDetectHost

runApothecary(){
	local -a cmd=()
	local engine_type="$TYPE"
	if [[ ! -f "$APOTHECARY_BIN" ]]; then
		echoError "apothecary not found: ${APOTHECARY_BIN}"
		return 1
	fi
	[[ -x "$APOTHECARY_BIN" ]] || chmod +x "$APOTHECARY_BIN" 2>/dev/null || true

	# `macos` is the public spelling; formulas and package paths use the
	# historical canonical target name `osx`.
	[[ "$engine_type" == "macos" ]] && engine_type="osx"
	cmd=( "$APOTHECARY_BIN" -t "$engine_type" )
	[[ -n "$ARCH" ]] && cmd+=( -a "$ARCH" )
	cmd+=( -b "$BUILD_DIR" -d "$OUTPUT_FOLDER" )
	[[ "$FORCE" = 1 ]] && cmd+=( -f )
	[[ "$VERBOSE" = 1 ]] && cmd+=( -v )
	cmd+=( "$@" )

	echoVerbose "run: ${cmd[*]}"
	echoNote "${cmd[*]}"
	"${cmd[@]}"
}

pickArch(){
	local t="${1:-$TYPE}"
	local -a opts=() arches
	local a
	read -r -a arches <<< "$(archesForType "$t")"
	for a in "${arches[@]}"; do
		if [[ "$a" == "$ARCH" || "$a" == "$HOST_ARCH" ]]; then
			opts+=("${a}  (current)|${a}")
		else
			opts+=("${a}|${a}")
		fi
	done
	opts+=("keep ${ARCH}|${ARCH}")
	menuPick "Architecture  ·  ${t}" "${opts[@]}" || return 1
	ARCH="$UI_MENU_RESULT"
	export ARCH
}

pickAction(){
	menuPick "Apothecary command" \
		"update   (download + build + copy)|update" \
		"download (source only)|download" \
		"build    (compile only)|build" \
		"copy     (install libs)|copy" \
		"clean    (build tree)|clean" \
		"remove   (build cache)|remove" \
		"remove-all (cache + libs)|remove-all" \
		|| return 1
	ACTION="$UI_MENU_RESULT"
}

pickForce(){
	if confirmYes "Force re-download even if build folder exists?"; then
		FORCE=1
	else
		FORCE=0
	fi
}

cmdRunBuild(){
	local action="$1"
	shift
	local -a libs=("$@")
	local label

	if [[ ${#libs[@]} -eq 0 ]]; then
		echoError "no libraries specified"
		return 1
	fi

	label=$(IFS=, ; echo "${libs[*]}")
	printBanner "$action"
	echoInfo "${action}  ·  ${TYPE} / ${ARCH}"
	echoKV "libs" "$label"
	echoKV "force" "$FORCE"
	echoKV "out" "$OUTPUT_FOLDER"
	printf '\n'

	if ! confirmYes "Run apothecary ${action} for [${label}]?"; then
		echoInfo "cancelled"
		return 0
	fi

	tasksBegin "Tasks" \
		"Platform" \
		"Action" \
		"Apothecary ${action}" \
		"Finish"

	taskSet 0 done "${TYPE} / ${ARCH}"
	taskSet 1 done "${action}${FORCE:+ · force}"

	if ! taskLive 2 -- runApothecary "$action" "${libs[@]}"; then
		tasksSkipRest
		tasksSummary
		return 1
	fi
	taskTickLine 3 done
	tasksSummary
	printf '\n'
	echoSuccess "done  ·  ${action} ${label}"
	echoNote "output: ${OUTPUT_FOLDER}"
	printf '\n'
}

printHelp(){
	local prog
	prog=$(basename "${0:-apo}")
	printBanner "cli"
	cat << EOF

  Usage
    ${prog}                              Interactive menu (TTY)
    ${prog} <command> [args]             CLI command

  Commands
    menu                            Interactive menu
    update   [lib ...]              Download + build + copy
    download [lib ...]              Download sources
    build    [lib ...]              Build
    modular  [lib|addon|script ...] Stage XCFramework output in xout
    variant  <profile> [action]     Build/package an isolated modular variant
    clean    [lib ...]              Clean build
    remove   [lib ...]              Remove from build cache
    platforms                       List build platforms
    formulas                        List library formulas
    status                          Host + paths summary
    demo                            Preview task animations
    version                         CLI version

  Options / env
    TYPE=osx ARCH=arm64             Build type / architecture
    FORCE=1                         Force re-download (-f)
    VERBOSE=1  NO_COLOR=1  UI_ANIM=0

  Examples
    ${prog}
    ${prog} update zlib
    TYPE=ios ARCH=arm64 ${prog} modular path/to/formula.sh
    TYPE=linux ARCH=x86_64 ${prog} variant opencv-cuda-ai
    TYPE=android ARCH=arm64 ${prog} update openssl
    ${prog} formulas

EOF
	if [[ "$UI_HAS_GUM" -eq 1 ]]; then
		echoNote "gum detected — menus, confirms, banner"
	else
		echoNote "tip: brew install gum  → arrow-key menus"
	fi
	printf '\n'
	echoKV "host" "${HOST_OS} / ${HOST_ARCH}"
	echoKV "type" "$TYPE"
	echoKV "arch" "$ARCH"
	echoKV "formulas" "$(formulaCount)"
	printf '\n'
}

cmdStatus(){
	printBanner "status"
	printf '\n'
	echoKV "host" "${HOST_OS} / ${HOST_ARCH}"
	echoKV "type" "$TYPE"
	echoKV "arch" "$ARCH"
	echoKV "action" "$ACTION"
	echoKV "force" "$FORCE"
	echoKV "root" "$APOTHECARY_DIR"
	echoKV "formulas" "$FORMULAS_DIR"
	echoKV "out" "$OUTPUT_FOLDER"
	echoKV "build" "$BUILD_DIR"
	echoKV "engine" "$APOTHECARY_BIN"
	echoKV "libs" "$(formulaCount) formulas"
	printf '\n'
}

cmdPlatforms(){
	local t mark
	printBanner "platforms"
	printf '\n'
	printf '  %sBuild types%s\n' "$C_BOLD" "$C_RESET"
	for t in "${VALID_TYPES[@]}"; do
		mark="  "
		[[ "$t" == "$TYPE" ]] && mark="${C_OK}✓ ${C_RESET}"
		if typeHasScripts "$t"; then
			printf '  %s%s%s%s  %s%s%s\n' "$mark" "$C_FG" "$t" "$C_RESET" "$C_MUTED" "$(archesForType "$t")" "$C_RESET"
		else
			printf '  %s%s%s%s  %s(no scripts/)%s\n' "$mark" "$C_MUTED" "$t" "$C_RESET" "$C_DIM" "$C_RESET"
		fi
	done
	printf '\n'
	echoKV "default" "$DEFAULT_TYPE"
	echoKV "active" "$TYPE / $ARCH"
	printf '\n'
}

cmdFormulas(){
	local name
	printBanner "formulas"
	printf '\n'
	printf '  %sLibraries%s  %s(%s)%s\n' "$C_BOLD" "$C_RESET" "$C_MUTED" "$(formulaCount)" "$C_RESET"
	printf '  %s────────────────────────────────────────%s\n' "$C_MUTED" "$C_RESET"
	while IFS= read -r name; do
		[[ -n "$name" ]] || continue
		printf '  %s○%s  %s%s%s\n' "$C_ACCENT" "$C_RESET" "$C_FG" "$name" "$C_RESET"
	done < <(listFormulas)
	printf '\n'
}

cmdDemo(){
	printBanner "demo"
	tasksBegin "Tasks" \
		"Detect host platform" \
		"Scan formulas" \
		"Resolve build type" \
		"Simulate mix" \
		"Write summary"
	taskSet 0 running
	sleep 0.15
	taskSet 0 done "${HOST_OS} / ${HOST_ARCH}"
	taskRun 1 -- sleep 0.7
	taskSet 1 done "$(formulaCount) libraries"
	taskRun 2 -- sleep 0.5
	taskSet 2 done "$TYPE"
	taskRun 3 -- sleep 1.0
	taskSet 3 done "potion ready"
	taskSet 4 running
	sleep 0.2
	taskSet 4 done
	tasksSummary
}

cmdMenuPickPlatform(){
	local -a opts=()
	local t
	for t in "${VALID_TYPES[@]}"; do
		if [[ "$t" == "$DEFAULT_TYPE" ]]; then
			opts+=("${t}  (this machine)|${t}")
		else
			opts+=("${t}|${t}")
		fi
	done
	menuPick "Build platform" "${opts[@]}" || return 1
	TYPE="$UI_MENU_RESULT"
	export TYPE TARGET="$TYPE"
	echoSuccess "type → ${TYPE}"
	pickArch "$TYPE" || true
	echoSuccess "arch → ${ARCH}"
}

cmdMenuPickLibrary(){
	local -a opts=()
	local name lib
	opts+=("★  all core formulas|__core__")
	while IFS= read -r name; do
		[[ -n "$name" ]] && opts+=("${name}|${name}")
	done < <(listFormulas)
	if [[ ${#opts[@]} -lt 2 ]]; then
		echoError "no formulas found in ${FORMULAS_DIR}"
		return 1
	fi
	menuPick "Library  ·  ${TYPE} / ${ARCH}" "${opts[@]}" || return 1
	lib="$UI_MENU_RESULT"

	pickAction || return 1
	pickForce || true

	if [[ "$lib" == "__core__" ]]; then
		cmdRunBuild "$ACTION" core
	else
		cmdRunBuild "$ACTION" "$lib"
	fi
}

cmdMenuBuildHost(){
	TYPE="$DEFAULT_TYPE"
	export TYPE TARGET="$TYPE"
	ARCH="$HOST_ARCH"
	export ARCH

	printBanner "build"
	echoInfo "host build  ·  ${TYPE} / ${ARCH}"
	printf '\n'

	menuCanRun && pickArch "$TYPE" || true
	cmdMenuPickLibrary
}

cmdMenuBuildType(){
	cmdMenuPickPlatform || return 1
	cmdMenuPickLibrary
}

cmdMenuSettings(){
	local choice
	menuPick "Settings" \
		"Platform (${TYPE})|platform" \
		"Architecture (${ARCH})|arch" \
		"Toggle force (${FORCE})|force" \
		"Back|back" \
		|| return 0
	choice="$UI_MENU_RESULT"
	case "$choice" in
		platform) cmdMenuPickPlatform ;;
		arch)     pickArch "$TYPE" ;;
		force)
			if [[ "$FORCE" = 1 ]]; then FORCE=0; else FORCE=1; fi
			echoSuccess "force → ${FORCE}"
			;;
		back) ;;
	esac
}

cmdMenu(){
	local choice
	if ! menuCanRun; then
		echoWarning "no interactive TTY — showing help instead"
		printHelp
		return 1
	fi

	while true; do
		printf '\n'
		printBanner "menu"
		printf '\n'
		echoKV "host" "${HOST_OS} / ${HOST_ARCH}"
		echoKV "type" "$TYPE"
		echoKV "arch" "$ARCH"
		echoKV "force" "$FORCE"
		echoKV "formulas" "$(formulaCount)"
		echoKV "out" "$OUTPUT_FOLDER"
		printf '\n'

		if ! menuPick "What do you want to do?" \
			"Build for this machine (${DEFAULT_TYPE})|build-host" \
			"Build for platform…|build-type" \
			"Choose library (current type)|library" \
			"Build modular OpenCV CUDA/AI variant|variant" \
			"Settings (type / arch / force)|settings" \
			"List platforms|list-platforms" \
			"List formulas|list-formulas" \
			"Status|status" \
			"Preview UI demo|demo" \
			"Help|help" \
			"Quit|quit"
		then
			echoInfo "bye"
			return 0
		fi
		choice="$UI_MENU_RESULT"
		printf '\n'

		case "$choice" in
			build-host)     cmdMenuBuildHost; menuPause ;;
			build-type)     cmdMenuBuildType; menuPause ;;
			library)        cmdMenuPickLibrary; menuPause ;;
			variant)
				"$APOTHECARY_SCRIPTS/build-opencv-variant.sh" opencv-cuda-ai all
				menuPause
				;;
			settings)       cmdMenuSettings; menuPause ;;
			list-platforms) cmdPlatforms; menuPause ;;
			list-formulas)  cmdFormulas; menuPause ;;
			status)         cmdStatus; menuPause ;;
			demo)           cmdDemo; menuPause ;;
			help)           printHelp; menuPause ;;
			quit)           echoSuccess "bye"; return 0 ;;
			*)              echoError "unknown menu id: ${choice}"; menuPause ;;
		esac
	done
}

runCommand(){
	local cmd=$1
	shift || true
	case "$cmd" in
		help|-h|--help) printHelp ;;
		menu)           cmdMenu ;;
		demo)           cmdDemo ;;
		platforms)      cmdPlatforms ;;
		formulas|libs)  cmdFormulas ;;
		status)         cmdStatus ;;
		variant)
			if [[ $# -eq 0 ]]; then
				echoError "variant requires a profile (opencv-cuda or opencv-cuda-ai)"
				return 1
			fi
			"$APOTHECARY_SCRIPTS/build-opencv-variant.sh" "$@"
			;;
		version)
			printBanner "version"
			printf '\n'
			echoKV "cli" "$APO_SCRIPT_VERSION"
			printf '\n'
			;;
		update|download|build|copy|clean|remove|remove-all|remove-lib|framework|modular)
			if [[ $# -eq 0 ]]; then
				echoError "${cmd} requires a library name (or core)"
				echoNote "example: apo ${cmd} zlib"
				return 1
			fi
			if [[ "$cmd" == "modular" ]]; then
				cmdRunBuild framework "$@"
			else
				cmdRunBuild "$cmd" "$@"
			fi
			;;
		*)
			if [[ -f "$APOTHECARY_BIN" ]]; then
				echoNote "passthrough → apothecary ${cmd} $*"
				runApothecary "$cmd" "$@"
				return $?
			fi
			echoError "Unknown command: ${cmd}"
			echoNote "valid: menu, update, download, build, clean, platforms, formulas, status, demo, help"
			printf '\n'
			printHelp
			return 1
			;;
	esac
}

if [[ $# -eq 0 ]]; then
	if menuCanRun; then
		cmdMenu
		exit $?
	fi
	printHelp
	exit 1
fi

runCommand "$@"
exit $?
