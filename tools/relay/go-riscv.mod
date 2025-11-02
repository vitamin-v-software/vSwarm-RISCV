module mpla

go 1.21.6

replace github.com/giorgospour/vSwarm-proto-RISCV => ./vSwarm-proto-RISCV

require (
	github.com/giorgospour/vSwarm-proto-RISCV v0.0.0-00010101000000-000000000000
	github.com/sirupsen/logrus v1.9.3
	google.golang.org/grpc v1.65.0
)

require (
	github.com/golang/protobuf v1.5.4 // indirect
	github.com/vhive-serverless/vSwarm-proto v0.5.7 // indirect
	golang.org/x/net v0.25.0 // indirect
	golang.org/x/sys v0.20.0 // indirect
	golang.org/x/text v0.15.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20240528184218-531527333157 // indirect
	google.golang.org/protobuf v1.34.2 // indirect
)
