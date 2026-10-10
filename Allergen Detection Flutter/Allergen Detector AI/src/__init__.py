
from flask import Flask
from flask_cors import CORS

def create_app(test_config=None):
    app = Flask(__name__, instance_relative_config=True)
    
    app.config.from_object('src.config.Config')
    
    CORS(app)

    try:
        import os
        os.makedirs(app.instance_path)
    except OSError:
        pass

    from .api import routes
    app.register_blueprint(routes.bp)

    @app.route('/health')
    def health():
        return {'status': 'healthy'}

    return app
