# Distributed under the OSI-approved BSD 3-Clause License.
# See accompanying file LICENSE-BSD for details.

cmake_minimum_required(VERSION 3.25)
get_filename_component(SCRIPT_NAME "${CMAKE_CURRENT_LIST_FILE}" NAME_WE)
set(CMAKE_MESSAGE_INDENT "[${VERSION}][${LANGUAGE}] ")
set(CMAKE_MESSAGE_INDENT_BACKUP "${CMAKE_MESSAGE_INDENT}")
message(STATUS "-------------------- ${SCRIPT_NAME} --------------------")


set(CMAKE_MODULE_PATH   "${PROJ_CMAKE_MODULES_DIR}")
set(CMAKE_PROGRAM_PATH  "${PROJ_CONDA_DIR}"
                        "${PROJ_CONDA_DIR}/Library")
find_package(Git        MODULE REQUIRED)
find_package(Gettext    MODULE REQUIRED COMPONENTS Msgcat Msgmerge)
find_package(Sphinx     MODULE REQUIRED COMPONENTS Build)
include(LogUtils)
include(JsonUtils)
include(GettextUtils)


message(STATUS "Removing directory '${PROJ_OUT_REPO_DOCS_LOCALE_DIR}/'...")
if (EXISTS "${PROJ_OUT_REPO_DOCS_LOCALE_DIR}")
    file(REMOVE_RECURSE "${PROJ_OUT_REPO_DOCS_LOCALE_DIR}")
    remove_cmake_message_indent()
    message("")
    message("Removed '${PROJ_OUT_REPO_DOCS_LOCALE_DIR}/'.")
    message("")
    restore_cmake_message_indent()
else()
    remove_cmake_message_indent()
    message("")
    message("No need to remove '${PROJ_OUT_REPO_DOCS_LOCALE_DIR}/'.")
    message("")
    restore_cmake_message_indent()
endif()


message(STATUS "Copying .po files to the local repository...")
if (NOT LANGUAGE STREQUAL "all")
    set(PO_SRC_DIR  "${PROJ_L10N_VERSION_LOCALE_DIR}/${LANGUAGE}")
    set(PO_DST_DIR  "${PROJ_OUT_REPO_DOCS_LOCALE_DIR}/${LANGUAGE}")
else()
    set(PO_SRC_DIR  "${PROJ_L10N_VERSION_LOCALE_DIR}")
    set(PO_DST_DIR  "${PROJ_OUT_REPO_DOCS_LOCALE_DIR}")
endif()
remove_cmake_message_indent()
message("")
message("From: ${PO_SRC_DIR}/")
message("To:   ${PO_DST_DIR}/")
message("")
copy_po_from_src_to_dst(
    IN_SRC_DIR  "${PO_SRC_DIR}"
    IN_DST_DIR  "${PO_DST_DIR}")
message("")
restore_cmake_message_indent()


file(READ "${LANGUAGES_JSON_PATH}" LANGUAGES_JSON_CNT)
if (NOT LANGUAGE STREQUAL "all")
    set(LANGUAGE_LIST "${LANGUAGE}")
endif()


foreach(_LANGUAGE ${LANGUAGE_LIST})
    get_json_value_by_dot_notation(
        IN_JSON_OBJECT      "${LANGUAGES_JSON_CNT}"
        IN_DOT_NOTATION     ".${_LANGUAGE}.langtag"
        OUT_JSON_VALUE      _LANGTAG)


    # Parse KERNEL_RELEASE from the Linux Kernel's Makefile based on the following logic:
    # KERNELVERSION = $(VERSION)$(if $(PATCHLEVEL),.$(PATCHLEVEL)$(if $(SUBLEVEL),.$(SUBLEVEL)))$(EXTRAVERSION)
    message(STATUS "Parsing KERNEL_RELEASE from the Linux Kernel's Makefile...")
    set(MAKEFILE_PATH "${PROJ_OUT_REPO_DIR}/Makefile")
    if (NOT EXISTS "${MAKEFILE_PATH}")
        message(FATAL_ERROR "Makefile not found at: ${MAKEFILE_PATH}")
    endif()
    file(STRINGS "${MAKEFILE_PATH}" MAKEFILE_LINES LIMIT_COUNT 20)
    set(KERNEL_VERSION "")
    set(KERNEL_PATCHLEVEL "")
    set(KERNEL_SUBLEVEL "")
    set(KERNEL_EXTRAVERSION "")
    foreach(LINE ${MAKEFILE_LINES})
        if     (LINE MATCHES "^VERSION[ \t]*=[ \t]*(.+)$")
            string(STRIP "${CMAKE_MATCH_1}" KERNEL_VERSION)
        elseif (LINE MATCHES "^PATCHLEVEL[ \t]*=[ \t]*(.+)$")
            string(STRIP "${CMAKE_MATCH_1}" KERNEL_PATCHLEVEL)
        elseif (LINE MATCHES "^SUBLEVEL[ \t]*=[ \t]*(.+)$")
            string(STRIP "${CMAKE_MATCH_1}" KERNEL_SUBLEVEL)
        elseif (LINE MATCHES "^EXTRAVERSION[ \t]*=[ \t]*(.+)$")
            string(STRIP "${CMAKE_MATCH_1}" KERNEL_EXTRAVERSION)
        endif()
    endforeach()
    if (NOT KERNEL_VERSION)
        message(FATAL_ERROR "Could not parse VERSION from ${MAKEFILE_PATH}")
    endif()
    if (NOT KERNEL_PATCHLEVEL)
        set(KERNEL_PATCHLEVEL "0")
    endif()
    if (NOT KERNEL_SUBLEVEL)
        set(KERNEL_SUBLEVEL "0")
    endif()
    set(KERNEL_RELEASE "${KERNEL_VERSION}")
    if (NOT KERNEL_PATCHLEVEL STREQUAL "")
        set(KERNEL_RELEASE "${KERNEL_RELEASE}.${KERNEL_PATCHLEVEL}")
        if (NOT KERNEL_SUBLEVEL STREQUAL "")
            set(KERNEL_RELEASE "${KERNEL_RELEASE}.${KERNEL_SUBLEVEL}")
        endif()
    endif()
    set(KERNEL_RELEASE "${KERNEL_RELEASE}${KERNEL_EXTRAVERSION}")
    remove_cmake_message_indent()
    message("")
    message("KERNEL_VERSION       = ${KERNEL_VERSION}")
    message("KERNEL_PATCHLEVEL    = ${KERNEL_PATCHLEVEL}")
    message("KERNEL_SUBLEVEL      = ${KERNEL_SUBLEVEL}")
    message("KERNEL_EXTRAVERSION  = ${KERNEL_EXTRAVERSION}")
    message("KERNEL_RELEASE       = ${KERNEL_RELEASE}")
    message("")
    restore_cmake_message_indent()


    message(STATUS "Running 'sphinx-build' command with '${SPHINX_BUILDER}' builder to build documentation for '${_LANGUAGE}' language...")
    if (CMAKE_HOST_LINUX)
        set(ENV_PATH            "${PROJ_CONDA_DIR}/bin:$ENV{PATH}")
        set(ENV_LD_LIBRARY_PATH "${PROJ_CONDA_DIR}/lib:$ENV{ENV_LD_LIBRARY_PATH}")
        set(ENV_PYTHONPATH      "${PROJ_OUT_REPO_DOCS_EXTNS_DIR}")
        set(ENV_VARS_OF_SYSTEM  PATH=${ENV_PATH}
                                LD_LIBRARY_PATH=${ENV_LD_LIBRARY_PATH}
                                PYTHONPATH=${ENV_PYTHONPATH})
    else()
        message(FATAL_ERROR "Invalid OS platform. (${CMAKE_HOST_SYSTEM_NAME})")
    endif()
    set(ENV_srctree             "${PROJ_OUT_REPO_DIR}")
    set(ENV_VARS_OF_COMMON      srctree=${ENV_srctree})
    set(HTML_BASEURL            "${BASEURL_HREF}")
    set(CURRENT_LANGAUGE        "${_LANGTAG}")
    set(CURRENT_VERSION         "${VERSION}")
    set(WARNING_FILE_PATH       "${PROJ_BINARY_DIR}/log-${SPHINX_BUILDER}-${VERSION}-${_LANGTAG}.txt")
    remove_cmake_message_indent()
    message("")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E env
                ${ENV_VARS_OF_SYSTEM}
                ${ENV_VARS_OF_COMMON}
                ${Sphinx_BUILD_EXECUTABLE}
                -b ${SPHINX_BUILDER}
                -D version=${KERNEL_RELEASE}
                -D language=${_LANGUAGE}
                -D locale_dirs=${LOCALE_TO_SOURCE_DIR}              # Relative to <sourcedir>.
                -D templates_path=${TMPLS_TO_CONFIG_DIR}            # Relative to <configdir>.
                -D gettext_compact=${SPHINX_GETTEXT_COMPACT}
                -D gettext_additional_targets=${SPHINX_GETTEXT_TARGETS}
                -D html_baseurl=${HTML_BASEURL}                     # Passed to 'custom.py'.
                -D current_language=${CURRENT_LANGAUGE}             # Passed to 'custom.py'.
                -D current_version=${CURRENT_VERSION}               # Passed to 'custom.py'.
                -w ${WARNING_FILE_PATH}
                -j ${SPHINX_JOB_NUMBER}
                ${SPHINX_VERBOSE_ARGS}
                -c ${PROJ_OUT_REPO_DOCS_CONFIG_DIR}                 # <configdir>, where conf.py locates.
                ${PROJ_OUT_REPO_DOCS_SOURCE_DIR}                    # <sourcedir>, where index.rst locates.
                ${PROJ_OUT_BUILDER_DIR}/${_LANGTAG}/${VERSION}      # <outputdir>, where .html generates.
        WORKING_DIRECTORY ${PROJ_OUT_REPO_DOCS_DIR}
        ECHO_OUTPUT_VARIABLE
        ECHO_ERROR_VARIABLE
        RESULT_VARIABLE RES_VAR
        OUTPUT_VARIABLE OUT_VAR OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_VARIABLE  ERR_VAR ERROR_STRIP_TRAILING_WHITESPACE)
    if (RES_VAR EQUAL 0)
        if (ERR_VAR)
            string(APPEND WARNING_REASON
            "The command succeeded but had some warnings.\n\n"
            "    result:\n\n${RES_VAR}\n\n"
            "    stderr:\n\n${ERR_VAR}")
            message("${WARNING_REASON}")
        endif()
    else()
        string(APPEND FAILURE_REASON
        "The command failed with fatal errors.\n"
        "    result:\n${RES_VAR}\n"
        "    stderr:\n${ERR_VAR}")
        message(FATAL_ERROR "${FAILURE_REASON}")
    endif()
    message("")
    restore_cmake_message_indent()


    if (REMOVE_REDUNDANT)
        message(STATUS "Removing redundant files/directories...")
        file(REMOVE_RECURSE "${PROJ_OUT_BUILDER_DIR}/${_LANGTAG}/${VERSION}/.doctrees/")
        file(REMOVE         "${PROJ_OUT_BUILDER_DIR}/${_LANGTAG}/${VERSION}/.buildinfo")
        file(REMOVE         "${PROJ_OUT_BUILDER_DIR}/${_LANGTAG}/${VERSION}/objects.inv")
        file(GLOB RST_FILES "${PROJ_OUT_BUILDER_DIR}/${_LANGTAG}/${VERSION}/*.rst")
        remove_cmake_message_indent()
        message("")
        message("Removed '${PROJ_OUT_BUILDER_DIR}/${_LANGTAG}/${VERSION}/.doctrees/'.")
        message("Removed '${PROJ_OUT_BUILDER_DIR}/${_LANGTAG}/${VERSION}/.buildinfo'.")
        message("Removed '${PROJ_OUT_BUILDER_DIR}/${_LANGTAG}/${VERSION}/objects.inv'.")
        foreach(RST_FILE ${RST_FILES})
        file(REMOVE         "${RST_FILE}")
        message("Removed '${RST_FILE}'.")
        endforeach()
        message("")
        restore_cmake_message_indent()
    endif()
endforeach()
unset(_LANGUAGE)


#[============================================================[
# Configure redirecting index.html files.
#]============================================================]


set(REDIRECT_LANGTAG    "en-us")
set(REDIRECT_VERSION    "master")


message(STATUS "Configuring 'index.html' file to the root of the builder directory...")
set(REDIRECT_URL        "${REDIRECT_LANGTAG}/${REDIRECT_VERSION}/index.html")
file(MAKE_DIRECTORY     "${PROJ_OUT_BUILDER_DIR}")
configure_file(
    "${PROJ_CMAKE_CUSTOM_DIR}/index.html.in"
    "${PROJ_OUT_BUILDER_DIR}/index.html"
    @ONLY)
remove_cmake_message_indent()
message("")
message("From: ${PROJ_CMAKE_CUSTOM_DIR}/index.html.in")
message("To:   ${PROJ_OUT_BUILDER_DIR}/index.html")
message("")
restore_cmake_message_indent()


message(STATUS "Configuring 'index.html' file to the langtag subdir of the builder directory...")
remove_cmake_message_indent()
message("")
message("From: ${PROJ_CMAKE_CUSTOM_DIR}/index.html.in")
foreach(_LANGUAGE ${LANGUAGE_LIST})
    get_json_value_by_dot_notation(
        IN_JSON_OBJECT      "${LANGUAGES_JSON_CNT}"
        IN_DOT_NOTATION     ".${_LANGUAGE}.langtag"
        OUT_JSON_VALUE      _LANGTAG)
    set(REDIRECT_URL        "${REDIRECT_VERSION}/index.html")
    file(MAKE_DIRECTORY     "${PROJ_OUT_BUILDER_DIR}/${_LANGTAG}")
    configure_file(
        "${PROJ_CMAKE_CUSTOM_DIR}/index.html.in"
        "${PROJ_OUT_BUILDER_DIR}/${_LANGTAG}/index.html"
        @ONLY)
    message("To:   ${PROJ_OUT_BUILDER_DIR}/${_LANGTAG}/index.html")
endforeach()
unset(_LANGUAGE)
message("")
restore_cmake_message_indent()


#[============================================================[
# Configure the provenance dropdown.
#]============================================================]


set(UPSTREAM_DOCS   "https://docs.kernel.org")
set(UPSTREAM_REPO   "https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git")
set(INSERT_POINT    "div[role=\"main\"]")


message(STATUS "Configuring 'ltd-provenance.js' file to the version subdir of the builder directory...")
remove_cmake_message_indent()
message("")
message("From: ${PROJ_CMAKE_PLUGINS_DIR}/provenance/ltd-sphinx.js.in")
foreach(_LANGUAGE ${LANGUAGE_LIST})
    get_json_value_by_dot_notation(
        IN_JSON_OBJECT      "${LANGUAGES_JSON_CNT}"
        IN_DOT_NOTATION     ".${_LANGUAGE}.langtag"
        OUT_JSON_VALUE      _LANGTAG)
    set(CURRENT_VERSION     "${VERSION}")
    set(CURRENT_LANGUAGE    "${_LANGTAG}")
    file(MAKE_DIRECTORY "${PROJ_OUT_BUILDER_DIR}/${_LANGTAG}/${VERSION}")
    configure_file(
        "${PROJ_CMAKE_PLUGINS_DIR}/provenance/ltd-sphinx.js.in"
        "${PROJ_OUT_BUILDER_DIR}/${_LANGTAG}/${VERSION}/ltd-provenance.js"
        @ONLY)
    message("To:   ${PROJ_OUT_BUILDER_DIR}/${_LANGTAG}/${VERSION}/ltd-provenance.js")
endforeach()
message("")
restore_cmake_message_indent()


#[============================================================[
# Configure the flyout navigation menu.
#]============================================================]


message(STATUS "Configuring 'ltd-config.js' file to the root of the builder directory...")
file(MAKE_DIRECTORY "${PROJ_OUT_BUILDER_DIR}")
configure_file(
    "${PROJ_CMAKE_CUSTOM_DIR}/ltd-config.js"
    "${PROJ_OUT_BUILDER_DIR}/ltd-config.js"
    @ONLY)
remove_cmake_message_indent()
message("")
message("From: ${PROJ_CMAKE_CUSTOM_DIR}/ltd-config.js")
message("To:   ${PROJ_OUT_BUILDER_DIR}/ltd-config.js")
message("")
restore_cmake_message_indent()


message(STATUS "Configuring 'ltd-flyout.js' file to the root of the builder directory...")
file(MAKE_DIRECTORY "${PROJ_OUT_BUILDER_DIR}")
configure_file(
    "${PROJ_CMAKE_PLUGINS_DIR}/flyout/ltd-flyout.js"
    "${PROJ_OUT_BUILDER_DIR}/ltd-flyout.js"
    @ONLY)
remove_cmake_message_indent()
message("")
message("From: ${PROJ_CMAKE_PLUGINS_DIR}/flyout/ltd-flyout.js")
message("To:   ${PROJ_OUT_BUILDER_DIR}/ltd-flyout.js")
message("")
restore_cmake_message_indent()


message(STATUS "Configuring 'ltd-icon.svg' file to the root of the builder directory...")
file(MAKE_DIRECTORY "${PROJ_OUT_BUILDER_DIR}")
configure_file(
    "${PROJ_CMAKE_PLUGINS_DIR}/flyout/ltd-icon.svg"
    "${PROJ_OUT_BUILDER_DIR}/ltd-icon.svg"
    @ONLY)
remove_cmake_message_indent()
message("")
message("From: ${PROJ_CMAKE_PLUGINS_DIR}/flyout/ltd-icon.svg")
message("To:   ${PROJ_OUT_BUILDER_DIR}/ltd-icon.svg")
message("")
restore_cmake_message_indent()


message(STATUS "Configuring 'ltd-current.js' file to the version subdir of the builder directory...")
remove_cmake_message_indent()
message("")
message("From: ${PROJ_CMAKE_PLUGINS_DIR}/flyout/ltd-current.js.in")
foreach(_LANGUAGE ${LANGUAGE_LIST})
    get_json_value_by_dot_notation(
        IN_JSON_OBJECT      "${LANGUAGES_JSON_CNT}"
        IN_DOT_NOTATION     ".${_LANGUAGE}.langtag"
        OUT_JSON_VALUE      _LANGTAG)
    set(CURRENT_VERSION     "${VERSION}")
    set(CURRENT_LANGUAGE    "${_LANGTAG}")
    file(MAKE_DIRECTORY "${PROJ_OUT_BUILDER_DIR}/${_LANGTAG}/${VERSION}")
    configure_file(
        "${PROJ_CMAKE_PLUGINS_DIR}/flyout/ltd-current.js.in"
        "${PROJ_OUT_BUILDER_DIR}/${_LANGTAG}/${VERSION}/ltd-current.js"
        @ONLY)
    message("To:   ${PROJ_OUT_BUILDER_DIR}/${_LANGTAG}/${VERSION}/ltd-current.js")
endforeach()
unset(_LANGUAGE)
message("")
restore_cmake_message_indent()


#[============================================================[
# Display home pages of the built documentation.
#]============================================================]


message(STATUS "The '${SPHINX_BUILDER}' documentation is built succesfully!")
remove_cmake_message_indent()
message("")
foreach(_LANGUAGE ${LANGUAGE_LIST})
    get_json_value_by_dot_notation(
        IN_JSON_OBJECT      "${LANGUAGES_JSON_CNT}"
        IN_DOT_NOTATION     ".${_LANGUAGE}.langtag"
        OUT_JSON_VALUE      _LANGTAG)
    message("${_LANGUAGE} : ${PROJ_OUT_BUILDER_DIR}/${_LANGTAG}/${VERSION}/index.html")
endforeach()
message("")
restore_cmake_message_indent()
