package auth

import (
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type Claims struct {
	UserID string `json:"uid"`
	// PasswordVersion lets the middleware reject tokens issued before a password change.
	// PasswordVersion 让中间件拒绝在密码变更前签发的 token。
	PasswordVersion int64 `json:"pver"`
	jwt.RegisteredClaims
}

func SignToken(userID string, secret string, ttl time.Duration, passwordVersion int64) (string, error) {
	// Create JWT for the given user and password version.
	// 为指定用户和密码版本创建 JWT。
	claims := Claims{
		UserID:          userID,
		PasswordVersion: passwordVersion,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(ttl)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(secret))
}

func ParseToken(tokenStr string, secret string) (*Claims, error) {
	// Parse and validate JWT.
	// 解析并验证 JWT。
	token, err := jwt.ParseWithClaims(tokenStr, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		return []byte(secret), nil
	})
	if err != nil {
		return nil, err
	}
	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}
	return nil, jwt.ErrTokenInvalidClaims
}
