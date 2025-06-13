#!/bin/bash
set -Eeuo pipefail

envsubst < odoo.cfg.tpl > odoo.cfg 

exec "$@"
