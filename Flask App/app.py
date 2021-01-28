from flask import Flask,render_template
import pyodbc
import datetime
app = Flask(__name__)
#
conn = pyodbc.connect('Driver={ODBC Driver 17 for SQL Server};'
                      'Server=localhost;'
                      'Database=scooter;'
                      'Trusted_Connection=yes;')

#station address
addrcur = conn.cursor()
addrcur.execute('SELECT Station_Address FROM scooter.dbo.Docking_Station')
row = addrcur.fetchall()
station_addr = []
for i in range(0,len(row)):
    temp = row[i][0]
    station_addr.append(temp)

#station Name
snamecur = conn.cursor()
snamecur.execute('SELECT Station_Name FROM scooter.dbo.Docking_Station')
row = snamecur.fetchall()
station_name = []
for i in range(0,len(row)):
    temp = row[i][0]
    station_name.append(temp)
#
# station location
loccur = conn.cursor()
loccur.execute('SELECT coordinates FROM scooter.dbo.Docking_Station')
row = loccur.fetchall()
station_location = []
for i in range(0,len(row)):
    temp = row[i][0]
    station_location.append(temp)

cacur = conn.cursor()
cacur.execute('SELECT Docking_Capacity FROM scooter.dbo.Docking_Station')
row = cacur.fetchall()
station_capacity = []
for i in range(0,len(row)):
    temp = row[i][0]
    station_capacity.append(temp)

stcur = conn.cursor()
stcur.execute('SELECT Station_Status FROM scooter.dbo.Docking_Station')
row = stcur.fetchall()
station_status = []
for i in range(0, len(row)):
    temp = row[i][0]
    station_status.append(temp)



#fare
fares = conn.cursor()
fares.execute('SELECT * FROM scooter.dbo.Fares')
row = fares.fetchall()
time = []
fare = []
for i in range(0, len(row)):
    temp = row[i][1]
    temp1 = row[i][2]
    time.append(temp)
    fare.append(int(temp1))


scootertable = conn.cursor()
scootertable.execute('SELECT * FROM scooter.dbo.Scooter')
row = scootertable.fetchall()
id = []
model = []
modelyear= []
statusinuse = []
for i in range(0, len(row)):
    temp = row[i][0]
    temp1 = row[i][1]
    t2 = row[i][2]
    t3 = row[i][3]
    id.append(temp)
    model.append(temp1)
    modelyear.append(t2)
    statusinuse.append(t3)


ridetable = conn.cursor()
ridetable.execute('select scooter.dbo.Docking_Station.Station_Name,scooter.dbo.ride.Start_Time, scooter.dbo.ride.End_Time,scooter.dbo.ride.Scooter_Id '
                  'from scooter.dbo.ride '
                  'join scooter.dbo.Docking_Station on scooter.dbo.Docking_Station.Station_ID = scooter.dbo.ride.Start_Station_Id '
                  'where scooter.dbo.ride.Account_Id = \'U7275\'')
#
row = ridetable.fetchall()
start = []
start_time = []
end_time= []
scooterid = []
for i in range(0, len(row)):
    temp = row[i][0]
    temp1 = row[i][1]
    t2 = row[i][2]
    t3 = row[i][3]
    start.append(temp)
    start_time.append(temp1)
    end_time.append(t2)
    scooterid.append(t3)

ridetable1 = conn.cursor()
ridetable1.execute('select scooter.dbo.Docking_Station.Station_Name '
                  'from scooter.dbo.ride '
                  'join scooter.dbo.Docking_Station on scooter.dbo.Docking_Station.Station_ID = scooter.dbo.ride.End_Station_Id '
                  'where scooter.dbo.ride.Account_Id = \'U7275\'')
row = ridetable1.fetchall()
end = []
for i in range(0, len(row)):
    temp = row[i][0]
    end.append(temp)


# station_location=[[42.336371,-71.12092], [42.349206,-71.081971], [42.361592,-71.094412]]





@app.route('/')
@app.route('/index')
def index():
    return render_template('index.html')

@app.route('/station')
def station():
    return render_template('station.html',
                           station_location=station_location,
                           station_name=station_name,
                           station_addr=station_addr,
                           station_status=station_status,
                           station_capacity=station_capacity)

@app.route('/scooters')
def scooters():
    return render_template('scooters.html', id=id,modelyear=modelyear,model=model,statusinuse=statusinuse)

@app.route('/ridehistory')
def ridehistory():
    return render_template('ridehis.html', start_time=start_time,end_time=end_time,scooterid=scooterid,start=start,end=end)

@app.route('/fares')
def fares():
    return render_template('fares.html', fare=fare,time=time)

if __name__ == '__main__':
    app.run()
