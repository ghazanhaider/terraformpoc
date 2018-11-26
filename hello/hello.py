import cgi,json,subprocess,flask
from flask import Flask, redirect, url_for, request, make_response
parameters={}
TERRAFORM_CMD="/srv/terraform/terraform apply -auto-approve -var-file=creds.tfvars -var-file=params.tfvars"
app = Flask(__name__)

@app.route('/')
def form():
    page = '<html><head><title>TerraformPOC</title></head><body>'
    page += '<h3>Please enter VM parameters</h3>'
    page += '<form method="post" action="/create">'
    page += 'VM Name:'
    page += '<input type="text" name="vm_name"><br>'
    page += 'VM Size:'
    page += '<input type="text" name="vm_size"><br>'
    page += 'Resource Group:'
    page += '<input type="text" name="resource_group"><br>'
    page += 'Location/Region:'
    page += '<input type="text" name="location"><br>'
    page += 'Login username (for example azadmin):'
    page += '<input type="text" name="username"><br>'
    page += 'SSH public key'
    page += '<input type="text" name="ssh_key"><br>'
    page += '<input type="submit" value="Create VM"><br>'
    page += '</form></body></html>'
    return page

@app.route('/create',methods=['POST'])
def action():
    # Load up the dict
    parameters['vm_name']=request.form['vm_name']
    parameters['vm_size']=request.form['vm_size']
    parameters['resource_group']=request.form['resource_group']
    parameters['location']=request.form['location']
    parameters['username']=request.form['username']
    parameters['ssh_key']=request.form['ssh_key']

    # Write to file
    parameter_file = open("/srv/terraform/params.tfvars","w")
    parameter_file.write(json.dumps(parameters))
    parameter_file.close()

    # Run Terraform
    #proc = subprocess.call(TERRAFORM_CMD, 
    proc = subprocess.Popen(TERRAFORM_CMD,
            shell=True, 
            stdout=subprocess.PIPE, 
            stderr=subprocess.STDOUT,
            cwd="/srv/terraform")

    out,err = proc.communicate()

    page = "<html><head><title>Creating VM</title></head><body>"
    page += "<h3>Creating VM with the following command<br>"
    page += out
    page += "</body></html>"

    return page

    # Display result continuously on webpage
    #for line in proc.stdout:
    #    yield line.rstrip() + '<br/>\n'

    #return flask.Response(inner(), mimetype='text/html')


