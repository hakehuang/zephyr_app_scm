# Copyright 2022 NXP
# SPDX-License-Identifier: Apache-2.0

# Suppress "simple_bus_reg" on RW6XX boards as all GPIO ports use the same register.
list(APPEND EXTRA_DTC_FLAGS "-Wno-simple_bus_reg")
