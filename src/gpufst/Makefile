
all:

include ../kaldi.mk
LDFLAGS += $(CUDA_LDFLAGS)
LDLIBS += $(CUDA_LDLIBS)

CXXFLAGS += -O3
OBJFILES = 
ifeq ($(CUDA), true)
  OBJFILES += fst.o numberizer.o
endif

LIBNAME = kaldi-gpufst

ADDLIBS = 

# Make sure we have CUDA_ARCH from kaldi.mk,
ifeq ($(CUDA), true)
  ifndef CUDA_ARCH
    $(error CUDA_ARCH is undefined, run 'src/configure')
  endif
endif

# Implicit rule for kernel compilation,
%.o : %.cu
	$(CUDATKDIR)/bin/nvcc -c $< -O3 -o $@ $(CUDA_INCLUDE) $(CUDA_FLAGS) $(CUDA_ARCH) -I../

include ../makefiles/default_rules.mk
