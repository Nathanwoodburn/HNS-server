from flask import Flask, render_template_string, request, make_response
import json
import requests
import secrets
import varo_auth


app = Flask(__name__)
cookie = []

@app.route('/')
def index():
    if request.cookies.get('test_auth') != None:
        auth_cookie = request.cookies.get('test_auth')
        for i in cookie:
            if i['cookie'] == auth_cookie:
                return render_template_string(f'''
                <h1>Index Page</h1>
                <p>Welcome {i['name']}</p>
                ''')


    return render_template_string('''
                                  <script src="https://code.jquery.com/jquery-3.6.4.min.js"></script>
    <h1>Index Page</h1>
    <script type="text/javascript" src="https://auth.varo.domains/v1"></script>
    <script>var varo = new Varo();</script>
                                  <button onclick='varo.auth().then(auth => {
    if (auth.success) {
		// handle success by calling your api to update the users session
		$.post("/auth", JSON.stringify(auth.data), (response) => {
			window.location.reload();
		});
	}
    });'>Login</button>

    ''')

@app.route('/auth', methods=['POST'])
def auth():
    global cookie
    auth = varo_auth.flask_login(request)
    if auth == False:
        return render_template_string("Error")
    resp = make_response(render_template_string("Success"))
    # Gen cookie
    auth_cookie = secrets.token_hex(12 // 2)
    cookie.append({'name': auth, 'cookie': auth_cookie})
    resp.set_cookie('test_auth', auth_cookie)
    return resp



if __name__ == '__main__':
    app.run(debug=True)
