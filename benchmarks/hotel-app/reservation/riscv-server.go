// MIT License

// Copyright (c) 2022 EASE lab

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

package main

import (
	"fmt"
	"strconv"
	// "encoding/json"

	// "gopkg.in/mgo.v2"
	// "gopkg.in/mgo.v2/bson"
	// "strings"
	"net"

	log "github.com/sirupsen/logrus"

	"time"

	"github.com/bradfitz/gomemcache/memcache"
	"github.com/gocql/gocql"

	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"google.golang.org/grpc/keepalive"
	"google.golang.org/grpc/reflection"

	pb "github.com/vhive-serverless/vSwarm-proto/proto/hotel_reserv/reservation"
	// tracing "github.com/vhive-serverless/vSwarm/utils/tracing/go"
)

// Server implements the geo service
type Server struct {
	
	pb.UnimplementedReservationServer
	CassandraSession *gocql.Session
	Port             int
	IpAddr           string
	MemcClient   *memcache.Client

}

// Run starts the server
func (s *Server) Run() error {
	if s.Port == 0 {
		return fmt.Errorf("server port must be set")
	}

	opts := []grpc.ServerOption{
		grpc.KeepaliveParams(keepalive.ServerParameters{
			Timeout: 120 * time.Second,
		}),
		grpc.KeepaliveEnforcementPolicy(keepalive.EnforcementPolicy{
			PermitWithoutStream: true,
		}),
	}


	srv := grpc.NewServer(opts...)

	pb.RegisterReservationServer(srv, s)

	// Register reflection service on gRPC server.
	reflection.Register(srv)

	// listener
	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", s.Port))
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	log.Printf("Start Reservation server. Addr: %s:%d\n", s.IpAddr, s.Port)
	return srv.Serve(lis)
}

// CheckAvailability checks if given information is available
func (s *Server) CheckAvailability(ctx context.Context, req *pb.Request) (*pb.Result, error) {
	// log.Println("CheckAvailability")
	// print(*req)
	res := new(pb.Result)
	res.HotelId = make([]string, 0)

	
	session:= s.CassandraSession

	keyspace := "reservation_db"
	table1 := "reservation"
	table2 := "number"
	for _, hotelId := range req.HotelId {
		// fmt.Printf("reservation check hotel %s\n", hotelId)
		inDate, _ := time.Parse(
			time.RFC3339,
			req.InDate+"T12:00:00+00:00")
			
		outDate, _ := time.Parse(
			time.RFC3339,
			req.OutDate+"T12:00:00+00:00")
			
		indate := inDate.String()[0:10]

		for inDate.Before(outDate) {
			
			// check reservations
			count := 0
			inDate = inDate.AddDate(0, 0, 1)
			outdate := inDate.String()[0:10]
			fmt.Printf("hotel  %s, indate %s, outdate %s\n", hotelId, inDate.String()[0:10], outdate)

			// first check memc
			memc_key := hotelId + "_" + inDate.String()[0:10] + "_" + outdate
			item, err := s.MemcClient.Get(memc_key)

			if err == nil {
				// memcached hit
				count, _ = strconv.Atoi(string(item.Value))
				fmt.Printf("memcached hit %s = %d\n", memc_key, count)
			} else if err == memcache.ErrCacheMiss {
				resQuery := session.Query("SELECT roomnum FROM " + keyspace + "." + table1 +" WHERE hotelid = ? AND checkin = ? AND checkout = ?", hotelId, indate, outdate).Iter()
				if resQuery.NumRows() != 0 {
					var tempCount int
					for  {
						resQuery.Scan(&tempCount)
						count +=tempCount
					}	
				}

				// update memcached
				err = s.MemcClient.Set(&memcache.Item{Key: memc_key, Value: []byte(strconv.Itoa(count))})
				if err != nil {
					log.Warn("MMC error: ", err)
				}
			} else {
				fmt.Printf("Memmcached error = %s\n", err)
				panic(err)
			}

			// check capacity
			// check memc capacity
			memc_cap_key := hotelId + "_cap"
			item, err = s.MemcClient.Get(memc_cap_key)
			hotel_cap := 0

			if err == nil {
				// memcached hit
				hotel_cap, _ = strconv.Atoi(string(item.Value))
				fmt.Printf("memcached hit %s = %d\n", memc_cap_key, hotel_cap)
			} else if err == memcache.ErrCacheMiss {
				// var num int
				resQuery := session.Query("SELECT roomnum FROM " + keyspace + "." + table2 +" WHERE hotelid = ?", hotelId).Iter()
				if resQuery.NumRows() != 0 {
					resQuery.Scan(&hotel_cap)
				}
				
				// update memcached
				err = s.MemcClient.Set(&memcache.Item{Key: memc_cap_key, Value: []byte(strconv.Itoa(hotel_cap))})
				if err != nil {
					log.Warn("MMC error: ", err)
				}
			} else {
				fmt.Printf("Memmcached error = %s\n", err)
				panic(err)
			}
			fmt.Printf("requested + booked : %d, capacity : %d\n", count+int(req.RoomNumber), hotel_cap)	
			if count+int(req.RoomNumber) > hotel_cap {
				res.HotelId = append(res.HotelId, "Not enough capacity")
				break
			}
			indate = outdate

			if inDate.Equal(outDate) {
				res.HotelId = append(res.HotelId, hotelId)
			}
		}
	}

	return res, nil
}


// MakeReservation makes a reservation based on given information
func (s *Server) MakeReservation(ctx context.Context, req *pb.Request) (*pb.Result, error) {
	log.Println("MakeReservation")
	res := new(pb.Result)
	res.HotelId = make([]string, 0)

	session:= s.CassandraSession

	keyspace := "reservation_db"
	table1 := "reservation"
	table2 := "number"

	inDate, _ := time.Parse(
		time.RFC3339,
		req.InDate+"T12:00:00+00:00")

	outDate, _ := time.Parse(
		time.RFC3339,
		req.OutDate+"T12:00:00+00:00")
	hotelId := req.HotelId[0]

	indate := inDate.String()[0:10]

	memc_date_num_map := make(map[string]int)

	for inDate.Before(outDate) {
		// check reservations
		count := 0
		inDate = inDate.AddDate(0, 0, 1)
		outdate := inDate.String()[0:10]

		// first check memc
		memc_key := hotelId + "_" + inDate.String()[0:10] + "_" + outdate
		item, err := s.MemcClient.Get(memc_key)
		if err == nil {
			// memcached hit
			count, _ = strconv.Atoi(string(item.Value))
			fmt.Printf("memcached hit %s = %d\n", memc_key, count)
			memc_date_num_map[memc_key] = count + int(req.RoomNumber)

		} else if err == memcache.ErrCacheMiss {
			// memcached miss
			fmt.Printf("memcached miss\n")
		
			resQuery := session.Query("SELECT roomnum FROM " + keyspace + "." + table1 +" WHERE hotelid = ? AND checkin = ? AND checkout = ?", hotelId, indate, outdate).Iter()
				// fmt.Printf("reservation results = %v\n", reserve)
			if resQuery.NumRows() != 0 {
				var tempCount int
				for  {
					resQuery.Scan(&tempCount)
					count +=tempCount
				}	
			}

			memc_date_num_map[memc_key] = count + int(req.RoomNumber)

		} else {
			fmt.Printf("Memmcached error = %s\n", err)
			panic(err)
		}

		// check capacity
		// check memc capacity
		memc_cap_key := hotelId + "_cap"
		item, err = s.MemcClient.Get(memc_cap_key)
		hotel_cap := 0
		if err == nil {
			// memcached hit
			hotel_cap, _ = strconv.Atoi(string(item.Value))
			fmt.Printf("memcached hit %s = %d\n", memc_cap_key, hotel_cap)
		} else if err == memcache.ErrCacheMiss {
			// memcached miss
			resQuery := session.Query("SELECT roomnum FROM " + keyspace + "." + table2 +" WHERE hotelid = ?", hotelId).Iter()
			if resQuery.NumRows() != 0 {
				resQuery.Scan(&hotel_cap)
			}
			// write to memcache
			err = s.MemcClient.Set(&memcache.Item{Key: memc_cap_key, Value: []byte(strconv.Itoa(hotel_cap))})
			if err != nil {
				log.Warn("MMC error: ", err)
			}
		} else {
			fmt.Printf("Memmcached error = %s\n", err)
			panic(err)
		}

		if count+int(req.RoomNumber) > hotel_cap {
			fmt.Printf("Not enough space left\n")
			return res, nil
		}
		indate = outdate
	}

	// only update reservation number cache after check succeeds
	for key, val := range memc_date_num_map {
		err := s.MemcClient.Set(&memcache.Item{Key: key, Value: []byte(strconv.Itoa(val))})
		if err != nil {
			log.Warn("MMC error: ", err)
		}
	}

	inDate, _ = time.Parse(
		time.RFC3339,
		req.InDate+"T12:00:00+00:00")

	indate = inDate.String()[0:10]

	for inDate.Before(outDate) {
		inDate = inDate.AddDate(0, 0, 1)
		outdate := inDate.String()[0:10]
		// err := c.Insert(&Reservation{
		// 	HotelId:      hotelId,
		// 	CustomerName: req.CustomerName,
		// 	InDate:       indate,
		// 	OutDate:      outdate,
		// 	Number:       int(req.RoomNumber)})
		// if err != nil {
		// 	panic(err)
		// }
		err := session.Query("INSERT INTO " + keyspace + "." + table1 + " (hotelid, checkin, checkout, roomnum) VALUES (?, ?, ?, ?)", hotelId, indate, outdate, int(req.RoomNumber)).Exec()
		if err != nil {
			panic(err)
		}
		indate = outdate
	}

	res.HotelId = append(res.HotelId, hotelId)

	return res, nil
}

type Reservation struct {
	HotelId      string `bson:"hotelid"`
	CustomerName string `bson:"customername"`
	InDate       string `bson:"indate"`
	OutDate      string `bson:"outdate"`
	Number       int    `bson:"number"`
}

type Number struct {
	HotelId string `bson:"hotelid"`
	Number  int    `bson:"numberofroom"`
}
