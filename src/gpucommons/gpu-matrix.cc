#include "gpucommons/gpu-matrix.h"

namespace kaldi{

template<typename Real>
_GPUMatrix::_GPUMatrix(Matrix<Real> &M) :
  numcols_(M.NumCols()),
  numrows_(M.NumRows()),
  stride_(M.Stride())
{
  const size_t m_dim = M.SizeInBytes() / sizeof(Real);
  Real* m_data = M.Data();

  thrust::copy(m_data, m_data + m_dim, data_.begin());
  data = data_.data().get();
}

template<typename Real>
_GPUMatrix::_GPUMatrix(const Matrix<Real> &M) :
  numcols_(M.NumCols()),
  numrows_(M.NumRows()),
  stride_(M.Stride())
{
  const size_t m_dim = M.SizeInBytes() / sizeof(Real);
  Real* m_data = M.Data();

  thrust::copy(m_data, m_data + m_dim, data_.begin());
  data = data_.data().get();
}

template<typename Real>
int32 _GPUMatrix::NumRows() const { return numrows_; }

template<typename Real>
int32 _GPUMatrix::NumCols() const { return numcols_; }

template<typename Real>
int32 _GPUMatrix::Stride() const { return stride_; }

template<typename Real>
int32 _GPUMatrix::Index(int32 r, int32 c) const { return r * stride_ + c; }

}
