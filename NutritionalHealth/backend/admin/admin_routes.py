from flask import Blueprint, request, jsonify
import os
import json

from models import db, Report, History

admin_bp = Blueprint('admin_bp', __name__)

def _check_admin_secret(req):
    # Default ADMIN_SECRET set so a local admin can be used without creating a user.
    # WARNING: keep this secret safe in production; override via environment variable.
    admin_secret = os.environ.get('ADMIN_SECRET', '12345678zA*')
    provided = req.headers.get('X-Admin-Secret') or req.args.get('admin_secret')
    return admin_secret and provided == admin_secret


@admin_bp.route('/reports', methods=['GET'])
def list_reports():
    if not _check_admin_secret(request):
        return jsonify({'error': 'forbidden'}), 403

    reps = Report.query.order_by(Report.created_at.desc()).limit(500).all()

    out = []
    for r in reps:
        out.append({
            'id': r.id,
            'user_id': r.user_id,
            'type': r.type,
            'detail': r.detail,
            'created_at': r.created_at.isoformat()
        })

    return jsonify({'reports': out})


@admin_bp.route('/submissions', methods=['GET'])
def list_submissions():
    if not _check_admin_secret(request):
        return jsonify({'error': 'forbidden'}), 403

    subs = History.query.order_by(History.created_at.desc()).limit(1000).all()

    out = []
    for s in subs:
        data = s.data
        try:
            data = json.loads(s.data) if isinstance(s.data, str) else s.data
        except Exception:
            pass

        out.append({
            'id': s.id,
            'user_id': s.user_id,
            'data': data,
            'created_at': s.created_at.isoformat()
        })

    return jsonify({'submissions': out})


@admin_bp.route('/export/submissions/csv', methods=['GET'])
def export_submissions_csv():
    if not _check_admin_secret(request):
        return jsonify({'error': 'forbidden'}), 403

    from flask import Response
    from io import StringIO
    import csv

    subs = History.query.order_by(History.created_at.asc()).all()

    buf = StringIO()
    writer = csv.writer(buf)

    writer.writerow(['id', 'user_id', 'created_at', 'data'])

    for s in subs:
        writer.writerow([
            s.id,
            s.user_id or '',
            s.created_at.isoformat(),
            json.dumps(s.data)
        ])

    return Response(
        buf.getvalue(),
        mimetype='text/csv; charset=utf-8',
        headers={'Content-Disposition': 'attachment; filename=submissions.csv'}
    )
