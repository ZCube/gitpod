// Copyright (c) 2022 Gitpod GmbH. All rights reserved.
// Licensed under the GNU Affero General Public License (AGPL).
// See License-AGPL.txt in the project root for license information.

package experimental

type Config struct {
	Observability *Observability `json:"observability"`
}

type Observability struct {
	Tracing *Tracing `json:"tracing,omitempty"`
}

type Tracing struct {
	SamplerType  *TracingSampleType `json:"samplerType,omitempty" validate:"omitempty,tracing_sampler_type"`
	SamplerParam *float64           `json:"samplerParam,omitEmpty" validate:"required_with=SamplerType"`
}

type TracingSampleType string

// Values taken from https://github.com/jaegertracing/jaeger-client-go/blob/967f9c36f0fa5a2617c9a0993b03f9a3279fadc8/config/config.go#L71
const (
	TracingSampleTypeConst         TracingSampleType = "const"
	TracingSampleTypeProbabilistic TracingSampleType = "probabilistic"
	TracingSampleTypeRateLimiting  TracingSampleType = "rateLimiting"
	TracingSampleTypeRemote        TracingSampleType = "remote"
)
