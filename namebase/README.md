# Namebase scripts


## Bulk accept all offers over a threshold

Simply get your Namebase token then run this command replacing these variables
- `<minimum offer to accept>`: the minimum offer you want to accept (eg. `10` for 10 HNS)
- `<token>`: your Namebase-main cookie

```
python3 accept.py --token <token> --threshold <minimum offer to accept>
```