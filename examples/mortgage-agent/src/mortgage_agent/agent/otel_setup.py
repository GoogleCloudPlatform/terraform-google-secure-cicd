# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Thin AdkApp subclass relying on Agent Engine default telemetry."""

from __future__ import annotations

import logging
import os
import sys

from vertexai.agent_engines import AdkApp

logger = logging.getLogger(__name__)


def _noop_telemetry_probe(*args, **kwargs):
    logger.info(
        "Skipping AdkApp telemetry API probe (Agent Gateway RST workaround)"
    )
    return None


class InstrumentedAdkApp(AdkApp):
    """AdkApp that uses the default Agent Engine telemetry pipeline.

    The default _default_instrumentor_builder() sets up:
    - TracerProvider with OTLP export to telemetry.googleapis.com/v1/traces
    - GenAI SDK instrumentation
    - Proper resource attributes for Agent Engine dashboard

    ADK already creates semantic spans (execute_tool, tools/call, call_llm)
    for agent operations, so no additional HTTP-level instrumentation
    is needed.
    """

    def project_id(self):
        # AdkApp.project_id() calls cloudresourcemanager.GetProject. Through
        # Agent Gateway AGENT_TO_ANYWHERE that gRPC can fail IPv6
        # (Network is unreachable) and retry for 60s; the SDK only fail-opens
        # PermissionDenied/Unauthenticated, so set_up aborts the engine.
        project = self._tmpl_attrs.get("project")
        env_project = os.environ.get("GOOGLE_CLOUD_PROJECT")
        if env_project and not str(env_project).isdigit():
            return env_project
        if project and not str(project).isdigit():
            return str(project)
        # Number-only (Agent Engine often stores project_number). Do not call
        # CRM — that is the 60s IPv6 timeout that aborts boot.
        return env_project or project

    def set_up(self):
        # AdkApp.set_up() POSTs to telemetry.googleapis.com/v1/traces when
        # enable_tracing=True. That probe has no try/except; AGENT_TO_ANYWHERE
        # can RST it and the control plane treats it as fatal.
        #
        # Patch AdkApp.set_up.__globals__ (the dict LOAD_GLOBAL uses), not
        # self._warn_if_telemetry_api_disabled — the SDK calls a free function.
        restored = []

        def _install(mapping, key):
            if mapping is None or key not in mapping:
                return
            orig = mapping[key]
            if orig is _noop_telemetry_probe:
                return
            mapping[key] = _noop_telemetry_probe
            restored.append((mapping, key, orig))

        _install(
            getattr(AdkApp.set_up, "__globals__", None),
            "_warn_if_telemetry_api_disabled",
        )
        for mod in list(sys.modules.values()):
            _install(
                getattr(mod, "__dict__", None),
                "_warn_if_telemetry_api_disabled",
            )

        try:
            return super().set_up()
        finally:
            for mapping, key, orig in restored:
                mapping[key] = orig
