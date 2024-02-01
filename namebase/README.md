# Namebase scripts


## Bulk accept all offers over a threshold

Simply get your Namebase token then run this command replacing these variables
- `<minimum offer to accept>`: the minimum offer you want to accept (eg. `10` for 10 HNS)
- `<token>`: your Namebase-main cookie

```
python3 accept.py --token <token> --threshold <minimum offer to accept>
```

## Bulk watch domains

Create a txt file with 1 domain per line (eg. `domains.txt`) then run this command replacing these variables
- `<token>`: your Namebase-main cookie
- `<domains.txt>`: the path to your txt file

```
python3 watchlist.py --token <token> --domains <domains.txt>
```