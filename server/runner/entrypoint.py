import json
import resource
import signal
import sys


def timeout_handler(_signum, _frame):
    raise TimeoutError("execution timeout")


def main():
    request = json.loads(sys.stdin.read())
    source = request["sourceCode"]
    if len(source.encode("utf-8")) > 48 * 1024:
        raise ValueError("source too large")

    resource.setrlimit(resource.RLIMIT_CPU, (1, 1))
    resource.setrlimit(resource.RLIMIT_AS, (96 * 1024 * 1024, 96 * 1024 * 1024))
    signal.signal(signal.SIGALRM, timeout_handler)
    signal.alarm(2)

    # This worker intentionally exposes only a tiny challenge contract.
    # The container is still mandatory: Python-level restrictions are not a
    # security boundary by themselves.
    safe_builtins = {
        "len": len,
        "range": range,
        "enumerate": enumerate,
        "min": min,
        "max": max,
    }
    namespace = {"__builtins__": safe_builtins}
    exec(compile(source, "submission.py", "exec"), namespace, namespace)
    function = namespace.get("two_sum")
    if not callable(function):
        raise ValueError("submission must define two_sum(nums, target)")

    cases = [([2, 7, 11, 15], 9, [0, 1]), ([3, 2, 4], 6, [1, 2])]
    for nums, target, expected in cases:
        result = function(nums, target)
        if list(result) != expected:
            print(json.dumps({"status": "wrong_answer", "message": "Caso de teste falhou."}))
            return

    print(json.dumps({"status": "accepted", "message": "Todos os casos passaram."}))


try:
    main()
except Exception as error:
    print(json.dumps({"status": "failed", "message": str(error)}))
