package image

// operatorImage is the image of the operator, it be set by the linker when building the operator
var operatorImage string

func GetOperatorImage() string {
	if operatorImage == "" {
		return "muicoder/redis-operator:stable"
	}
	return operatorImage
}
