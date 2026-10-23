# Local overflow checks, Apple M1 Max / 64 GB, Ollama 0.35.1, 2026-10-22.
# Check 4: does Ollama ever allocate more than min(requested, trained window)
#   when the request is small? (/api/ps after num_ctx 2048, 8192, and omitted)
# Check 5: which message role is cut short and which is dropped whole when
#   the prompt overflows num_ctx.
# Usage: python3 -I m1max_ollama0351_overflow_roles_2026_10_22.py llama3.2:latest
import json, urllib.request, sys
U='http://127.0.0.1:11434'
def post(path, body):
    r=urllib.request.Request(U+path, json.dumps(body).encode(), {'Content-Type':'application/json'})
    return json.load(urllib.request.urlopen(r, timeout=600))
def ps(): return [(m['name'],m.get('context_length')) for m in json.load(urllib.request.urlopen(U+'/api/ps'))['models']]
model=sys.argv[1]
words='the river carries a quiet stone past the old mill toward the sea and '
big=(words*900).strip()   # ~60k chars
small='You are terse.'
q='Say OK.'
def run(label, msgs, ctx):
    d=post('/api/chat',{'model':model,'stream':False,'options':{'num_ctx':ctx,'num_predict':4},'messages':msgs})
    print(f'{label:<38} num_ctx {ctx:>6}  prompt_eval_count {d.get("prompt_eval_count")}  ps {ps()}')
# check 4
for ctx in (2048, 8192):
    run('check4: tiny prompt', [{'role':'user','content':q}], ctx)
post('/api/generate',{'model':model,'keep_alive':0})
d=post('/api/chat',{'model':model,'stream':False,'options':{'num_predict':4},'messages':[{'role':'user','content':q}]})
print(f'{"check4: tiny prompt, num_ctx omitted":<38} ps {ps()}')
# check 5: true size
run('fits: big as user', [{'role':'system','content':small},{'role':'user','content':big+' '+q}], 65536)
for ctx in (8192,16384):
    run('A big system prompt', [{'role':'system','content':big},{'role':'user','content':q}], ctx)
    run('B big single user message', [{'role':'system','content':small},{'role':'user','content':big+' '+q}], ctx)
    run('C big history msg + Understood + q', [{'role':'system','content':small},{'role':'user','content':big},{'role':'assistant','content':'Understood.'},{'role':'user','content':q}], ctx)
post('/api/generate',{'model':model,'keep_alive':0})
