# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

test_that("extension types can be registered and unregistered", {
  spec <- nanoarrow_extension_spec()
  register_nanoarrow_extension("some_ext", spec)
  expect_identical(resolve_nanoarrow_extension("some_ext"), spec)
  unregister_nanoarrow_extension("some_ext")
  expect_identical(resolve_nanoarrow_extension("some_ext"), NULL)
})

test_that("infer_nanoarrow_ptype() dispatches on registered extension spec", {
  register_nanoarrow_extension(
    "some_ext",
    nanoarrow_extension_spec(subclass = "some_spec_class")
  )
  on.exit(unregister_nanoarrow_extension("some_ext"))

  infer_nanoarrow_ptype_extension.some_spec_class <- function(spec, x, ...) {
    infer_nanoarrow_ptype_extension(NULL, x, ..., warn_unregistered = FALSE)
  }

  s3_register(
    "nanoarrow::infer_nanoarrow_ptype_extension",
    "some_spec_class",
    infer_nanoarrow_ptype_extension.some_spec_class
  )

  expect_identical(
    infer_nanoarrow_ptype(
      na_extension(na_struct(list(some_name = na_int32())), "some_ext")
    ),
    data.frame(some_name = integer())
  )
})

test_that("convert_array() dispatches on registered extension spec", {
  register_nanoarrow_extension(
    "some_ext",
    nanoarrow_extension_spec(subclass = "some_spec_class")
  )
  on.exit(unregister_nanoarrow_extension("some_ext"))

  convert_array_extension.some_spec_class <- function(spec, array, to, ...) {
    convert_array_extension(NULL, array, to, ..., warn_unregistered = FALSE)
  }

  s3_register(
    "nanoarrow::convert_array_extension",
    "some_spec_class",
    convert_array_extension.some_spec_class
  )

  expect_identical(
    convert_array(
      nanoarrow_extension_array(data.frame(some_name = 1:5), "some_ext")
    ),
    data.frame(some_name = 1:5)
  )
})

test_that("as_nanoarrow_array() dispatches on registered extension spec", {
  register_nanoarrow_extension(
    "some_ext",
    nanoarrow_extension_spec(subclass = "some_spec_class")
  )
  on.exit(unregister_nanoarrow_extension("some_ext"))

  expect_error(
    as_nanoarrow_array(
      data.frame(some_name = 1:5),
      schema = na_extension(
        na_struct(list(some_name = na_int32())),
        "some_ext"
      )
    ),
    "not implemented for extension"
  )

  as_nanoarrow_array_extension.some_spec_class <- function(spec, x, ..., schema = NULL) {
    nanoarrow_extension_array(x, "some_ext")
  }

  s3_register(
    "nanoarrow::as_nanoarrow_array_extension",
    "some_spec_class",
    as_nanoarrow_array_extension.some_spec_class
  )

  ext_array <- as_nanoarrow_array(
    data.frame(some_name = 1:5),
    schema = na_extension(
      na_struct(list(some_name = na_int32())),
      "some_ext"
    )
  )

  expect_identical(
    infer_nanoarrow_schema(ext_array)$metadata[["ARROW:extension:name"]],
    "some_ext"
  )
})