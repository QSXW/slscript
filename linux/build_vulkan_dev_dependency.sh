#!/bin/bash

if [ -z "$1" ]; then
    export BUILD_PREFIX=$(pwd)/Build
else
    export BUILD_PREFIX=$1
fi

echo "Targeted install path: $BUILD_PREFIX"

build_vulkan_headers()
{
    VULKAN_HEADERS_REPO="https://github.com/KhronosGroup/Vulkan-Headers.git"
    VULKAN_HEADERS_VERSION="sdk-1.2.198.0"

    git clone "$VULKAN_HEADERS_REPO" Vulkan-Headers --branch "$VULKAN_HEADERS_VERSION"
    cd Vulkan-Headers

    mkdir build && cd build

    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$BUILD_PREFIX" ..
    make -j$(nproc)
    make install

    echo "pc path:$BUILD_PREFIX"/vulkan.pc
    cat >""$BUILD_PREFIX"/vulkan.pc" <<EOF
prefix=$BUILD_PREFIX
includedir=\${prefix}/include

Name: vulkan
Version: 1.2.198.0
Description: Vulkan (Headers Only)
Cflags: -I\${includedir}
EOF
    sudo mv "$BUILD_PREFIX"/vulkan.pc /usr/lib/pkgconfig/

    cd ..
    
    wget -qO - http://packages.lunarg.com/lunarg-signing-key-pub.asc | sudo apt-key add -
    sudo wget -qO /etc/apt/sources.list.d/lunarg-vulkan-bionic.list http://packages.lunarg.com/vulkan/lunarg-vulkan-bionic.list
    sudo apt update
    sudo apt install vulkan-sdk
}

build_glslang_dependency()
{
    GLSLANG_REPO="https://github.com/KhronosGroup/glslang.git"

    git clone "$GLSLANG_REPO" glslang
    cd glslang
    python3 ./update_glslang_sources.py
    mkdir build && cd build

    cmake  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$BUILD_PREFIX" \
        -DBUILD_SHARED_LIBS=OFF -DBUILD_EXTERNAL=ON -DBUILD_TESTING=OFF -DENABLE_CTEST=OFF \
        -DENABLE_OPT=ON -DENABLE_HLSL=ON -DENABLE_GLSLANG_BINARIES=OFF ..

    make -j$(nproc)
    make install

    # cp "$BUILD_PREFIX/glslang" /usr/include
    # cp "$BUILD_PREFIX/spirv-tools" /usr/include

    cd ..
}

install_nvidia_driver()
{
    sudo apt install nvidia-440
    sudo apt install ubuntu-drivers-common
    sudo apt install nvidia-settings
    sudo reboot
}

build_vulkan_headers
build_glslang_dependency
