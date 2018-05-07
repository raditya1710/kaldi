#include "gpu/gpu-diag-gmm.h"
#include <algorithm>

#include <thrust/sort.h>
#include <thrust/copy.h>
#include <thrust/device_vector.h>
#include <thrust/execution_policy.h>
#include <thrust/fill.h>

#include <math_functions.h>

namespace kaldi{

__host__ __device__
int32 _GPUDiagGmm::Dim() const { return means_invvars_.NumCols(); }

_GPUDiagGmm::_GPUDiagGmm(DiagGmm &d):
  valid_gconsts_(d.valid_gconsts())
 {
  gconsts_ = GPUVector<BaseFloat>(d.gconsts());
  weights_ = GPUVector<BaseFloat>(d.weights());
  inv_vars_ = GPUMatrix<BaseFloat>(d.inv_vars());
  means_invvars_ = GPUMatrix<BaseFloat>(d.means_invvars());
 }

// TODO : Implement this!
__host__ __device__ BaseFloat _GPUDiagGmm::LogLikelihood(BaseFloat *data, int32 num_data){
  const double kGPUMinLogDiffDouble = Log(DBL_EPSILON);
  const float kGPUMinLogDiffFloat = Log(FLT_EPSILON);

  if (!valid_gconsts_)
    KALDI_ERR << "Must call ComputeGconsts() before computing likelihood";

  /* BEGIN LogLikelihoods */
  int32 num_loglikes = gconsts_.Dim();
  BaseFloat* loglikes = new BaseFloat[num_loglikes];
  for(int32 i = 0;i < num_loglikes; ++i) loglikes[i] = gconsts_.data[i];

  if (num_data != Dim()) {
    KALDI_ERR << "DiagGmm::ComponentLogLikelihood, dimension "
              << "mismatch " << num_data << " vs. "<< Dim();
  }

  BaseFloat* data_sq = new BaseFloat[num_data];
  for(int32 i = 0;i < num_data; ++i) data_sq[i] = data[i] * data[i];

  for(int i = 0;i < gconsts_.Dim(); ++i){
    for(int j = 0;j < num_data; ++j){
      loglikes[i] += means_invvars_.data[means_invvars_.Index(i, j)] * data[j];
      loglikes[i] -= 0.5 * inv_vars_.data[inv_vars_.Index(i, j)] * data_sq[j];
    }
  }

  /* END LogLikelihoods */

  /* Begin Log Sum Exp */
  BaseFloat max_elem = *(std::max_element(loglikes, loglikes + num_loglikes));

  BaseFloat cutoff;
  if (sizeof(BaseFloat) == 4) cutoff = max_elem + kGPUMinLogDiffFloat;
  else cutoff = max_elem + kGPUMinLogDiffDouble;
  double sum_relto_max_elem = 0.0;

  for (int32 i = 0; i < num_loglikes; i++) {
    BaseFloat f = loglikes[i];
    if (f >= cutoff)
      sum_relto_max_elem += Exp(f - max_elem);
  }
  BaseFloat log_sum = max_elem + Log(sum_relto_max_elem);
  /* End Log Sum Exp */

  if (isnan(log_sum) || isinf(log_sum))
    KALDI_ERR << "Invalid answer (overflow or invalid variances/features?)";

  delete [] loglikes;
  delete [] data_sq;
  return log_sum;
}

}
