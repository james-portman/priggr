package main

import (
	"fmt"
	"os"
	"time"

	// Loads of dependencies, and what?
	log "github.com/Sirupsen/logrus"
	"github.com/codegangsta/cli"
	"github.com/gin-gonic/gin"
	"github.com/jinzhu/gorm"
	_ "github.com/mattn/go-sqlite3"
)

// Global? Come at me, bro.
var db gorm.DB

type LogFormatter struct{}

func (f *LogFormatter) Format(entry *log.Entry) ([]byte, error) {
	return []byte(fmt.Sprintf("%s [%s] %s\n", entry.Time.Format("2006-01-02 15:04:05.000"), entry.Level.String(), entry.Message)), nil
}

type Paste struct {
	ID      int       `json:"-"`
	PasteID string    `json:"paste_id" gorm:"column:paste_id" sql:"unique_index"`
	Created time.Time `json:"created"`
	Syntax  string    `json:"syntax"`
	Paste   string    `json:"paste"`
	Expires int       `json:"expires"`
}

func realMain(c *cli.Context) {
	lvl, err := log.ParseLevel(c.String("loglevel"))
	if err != nil {
		fmt.Fprintf(os.Stderr, "Could not parse log level. Must be one of: debug, info, warning, error, panic, fatal\n")
		os.Exit(1)
	}

	formatter := &LogFormatter{}
	log.SetFormatter(formatter)
	log.SetOutput(os.Stderr)
	log.SetLevel(lvl)

	db, err = gorm.Open("sqlite3", c.String("database"))
	if err != nil {
		log.Fatalf("Could not open database from %s: %s", c.String("database"), err)
	}
	defer db.Close()

	db.AutoMigrate(Paste{})
	log.Debug("Database init done")

	r := gin.Default()
	r.GET("/p/:pasteid", getPaste)
	r.POST("/p", storePaste)

	log.Warningf("Priggr serving on %s:%d", c.String("bind"), c.Int("port"))
	r.Run(fmt.Sprintf("%s:%d", c.String("bind"), c.Int("port")))

}

func storePaste(c *gin.Context) {
	paste := Paste{}
	err := c.Bind(paste)
	if err != nil {
		c.JSON(400, gin.H{"message": "Could not marshal POST data"})
		return
	}

	paste.Created = time.Now()
}

func getPaste(c *gin.Context) {
	pasteid, ok := c.Get("pasteid")
	if !ok || pasteid == "" {
		c.JSON(400, gin.H{"message": "Paste ID not provided"})
		return
	}

	paste := Paste{}

	db.Find(&paste, "paste_id = ?", pasteid)

	if paste.Paste == "" {
		c.JSON(404, gin.H{"message": "Paste not found"})
		return
	}

	c.JSON(200, paste)
}

func main() {
	app := cli.NewApp()
	app.Name = "Priggr"
	app.Usage = "Go-based Pastebin-alike"
	app.Author = "Dane Elwell"
	app.Flags = []cli.Flag{
		cli.StringFlag{
			Name:  "loglevel, l",
			Value: "info",
			Usage: "Logging level: debug, info, warning, error, panic, fatal",
		},
		cli.StringFlag{
			Name:  "database, d",
			Value: "/var/lib/prigger/prigger.db",
			Usage: "Path to sqlite3 database",
		},
		cli.StringFlag{
			Name:  "bind, b",
			Value: "0.0.0.0",
			Usage: "Bind to this IP address",
		},
		cli.IntFlag{
			Name:  "port, p",
			Value: 8998,
			Usage: "Use this port for HTTP requests",
		},
	}

	app.Action = realMain
}
