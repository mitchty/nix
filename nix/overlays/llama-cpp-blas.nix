final: prev: {
  llama-cpp-blas = prev.llama-cpp.override {
    cudaSupport = false;
    rocmSupport = false;
    metalSupport = false;
    blasSupport = true;
  };
}
