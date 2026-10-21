"""Tests for market watchlist compatibility behavior."""


def _auth_headers(monkeypatch):
    from app.utils import auth

    monkeypatch.setattr(
        auth,
        "verify_token",
        lambda token: {
            "sub": "tester",
            "user_id": 1,
            "role": "user",
            "token_version": 1,
        },
    )
    return {"Authorization": "Bearer test-token"}


class _FakeCursor:
    def __init__(self, rows):
        self._rows = rows
        self.executed = []

    def execute(self, query, params=None):
        self.executed.append((query, params))

    def fetchall(self):
        return self._rows

    def close(self):
        pass


class _FakeConn:
    def __init__(self, rows):
        self._rows = rows
        self.committed = False

    def cursor(self):
        return _FakeCursor(self._rows)

    def commit(self):
        self.committed = True


class _FakeConnCtx:
    def __init__(self, rows):
        self._conn = _FakeConn(rows)

    def __enter__(self):
        return self._conn

    def __exit__(self, exc_type, exc, tb):
        return False


def test_watchlist_prices_uses_legacy_query_when_db_empty(client, monkeypatch):
    from app.routes import market

    monkeypatch.setattr(market, "get_db_connection", lambda: _FakeConnCtx([]))
    monkeypatch.setattr(
        market,
        "get_single_price",
        lambda m, s: {"market": m, "symbol": s, "price": 123.45, "change": 1.23, "changePercent": 4.56},
    )

    headers = _auth_headers(monkeypatch)
    resp = client.get(
        '/api/market/watchlist/prices?watchlist=[{"market":"Crypto","symbol":"BTC"},{"market":"USStock","symbol":"AAPL"}]',
        headers=headers,
    )

    assert resp.status_code == 200
    body = resp.get_json()
    assert body["code"] == 1
    assert sorted(body["data"], key=lambda x: x["symbol"]) == [
        {"market": "USStock", "symbol": "AAPL", "price": 123.45, "change": 1.23, "changePercent": 4.56},
        {"market": "Crypto", "symbol": "BTC/USDT", "price": 123.45, "change": 1.23, "changePercent": 4.56},
    ]


def test_watchlist_prices_prefers_db_rows_over_legacy_query(client, monkeypatch):
    from app.routes import market

    monkeypatch.setattr(
        market,
        "get_db_connection",
        lambda: _FakeConnCtx([{"market": "USStock", "symbol": "TSLA"}]),
    )
    seen = []

    def fake_price(m, s):
        seen.append((m, s))
        return {"market": m, "symbol": s, "price": 88.0, "change": 2.0, "changePercent": 3.0}

    monkeypatch.setattr(market, "get_single_price", fake_price)

    headers = _auth_headers(monkeypatch)
    resp = client.get(
        '/api/market/watchlist/prices?watchlist=[{"market":"Crypto","symbol":"BTC"}]',
        headers=headers,
    )

    assert resp.status_code == 200
    body = resp.get_json()
    assert body["code"] == 1
    assert body["data"] == [
        {"market": "USStock", "symbol": "TSLA", "price": 88.0, "change": 2.0, "changePercent": 3.0},
    ]
    assert seen == [("USStock", "TSLA")]
