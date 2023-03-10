// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

#ifndef R_MATERIALIZE_DIFFTIME_H_INCLUDED
#define R_MATERIALIZE_DIFFTIME_H_INCLUDED

#include <R.h>
#include <Rinternals.h>

#include "materialize_common.h"
#include "materialize_dbl.h"
#include "nanoarrow.h"

static inline int nanoarrow_materialize_difftime(struct RConverter* converter) {
  if (converter->ptype_view.sexp_type == REALSXP) {
    switch (converter->schema_view.type) {
      case NANOARROW_TYPE_NA:
        NANOARROW_RETURN_NOT_OK(nanoarrow_materialize_dbl(converter));
        return NANOARROW_OK;
      case NANOARROW_TYPE_TIME32:
      case NANOARROW_TYPE_TIME64:
      case NANOARROW_TYPE_DURATION:
        NANOARROW_RETURN_NOT_OK(nanoarrow_materialize_dbl(converter));
        break;
      default:
        return EINVAL;
    }

    double scale;
    switch (converter->ptype_view.r_time_units) {
      case R_TIME_UNIT_MINUTES:
        scale = 1.0 / 60;
        break;
      case R_TIME_UNIT_HOURS:
        scale = 1.0 / (60 * 60);
        break;
      case R_TIME_UNIT_DAYS:
        scale = 1.0 / (60 * 60 * 24);
        break;
      case R_TIME_UNIT_WEEKS:
        scale = 1.0 / (60 * 60 * 24 * 7);
        break;
      default:
        scale = 1.0;
        break;
    }

    switch (converter->schema_view.time_unit) {
      case NANOARROW_TIME_UNIT_SECOND:
        scale *= 1;
        break;
      case NANOARROW_TIME_UNIT_MILLI:
        scale *= 1e-3;
        break;
      case NANOARROW_TIME_UNIT_MICRO:
        scale *= 1e-6;
        break;
      case NANOARROW_TIME_UNIT_NANO:
        scale *= 1e-9;
        break;
      default:
        return EINVAL;
    }

    if (scale != 1) {
      double* result = REAL(converter->dst.vec_sexp);
      for (int64_t i = 0; i < converter->dst.length; i++) {
        result[converter->dst.offset + i] = result[converter->dst.offset + i] * scale;
      }
    }

    return NANOARROW_OK;
  }

  return EINVAL;
}

#endif
