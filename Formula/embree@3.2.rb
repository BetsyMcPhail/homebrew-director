# Copyright (c) 2018, Massachusetts Institute of Technology.
# Copyright (c) 2018, Toyota Research Institute.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

class EmbreeAT32 < Formula
  desc "High-performance ray tracing kernels"
  homepage "https://embree.github.io/"
  url "https://drake-homebrew.csail.mit.edu/mirror/embree-3.2.4.tar.gz"
  sha256 "3470870490c21fc58708641286c2fa99f2f27e9388a5c2d2d36cf479d7d9e759"
  head "https://github.com/embree/embree.git"

  bottle do
    cellar :any
    root_url "https://drake-homebrew.csail.mit.edu/bottles"
  end

  keg_only :versioned_formula

  depends_on "cmake" => :build
  depends_on "ispc" => :build
  depends_on "tbb"

  def install
    args = std_cmake_args + %w[
      -DBUILD_TESTING=OFF
      -DCMAKE_INSTALL_NAME_DIR=#{opt_lib}
      -DCMAKE_INSTALL_RPATH=#{opt_lib}
      -DEMBREE_IGNORE_CMAKE_CXX_FLAGS=OFF
      -DEMBREE_MAX_ISA=SSE4.2
      -DEMBREE_TUTORIALS=OFF
    ]

    mkdir "build" do
      system "cmake", *args, ".."
      system "make"
      system "make", "install"
    end

    rm_rf bin
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <assert.h>
      #include <xmmintrin.h>
      #include <embree3/rtcore.h>
      #ifndef _MM_SET_DENORMALS_ZERO_MODE
      #define _MM_DENORMALS_ZERO_ON (0x0040)
      #define _MM_DENORMALS_ZERO_MASK (0x0040)
      #define _MM_SET_DENORMALS_ZERO_MODE(x) (_mm_setcsr((_mm_getcsr() & ~_MM_DENORMALS_ZERO_MASK) | (x)))
      #endif
      int main() {
        _MM_SET_FLUSH_ZERO_MODE(_MM_FLUSH_ZERO_ON);
        _MM_SET_DENORMALS_ZERO_MODE(_MM_DENORMALS_ZERO_ON);
        RTCDevice device = rtcNewDevice("verbose=1");
        assert(device != 0);
        rtcReleaseDevice(device);
        return 0;
      }
    EOS

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lembree3"
    system "./a.out"
  end
end