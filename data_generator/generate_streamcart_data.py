import csv
import json
import random
from datetime import datetime, timedelta

random.seed(42)

NUM_ORDERS = 2500
NUM_PRODUCTS = 2200

first_names = ["JOHN","JANE","AMIT","PRIYA","RAHUL","ANITA","DAVID","EMMA","ROHAN","NEHA"]
last_names = ["DOE","SMITH","PATEL","SHAH","KUMAR","SINGH","BROWN","JONES"]
cities = [("mumbai","MH"),("delhi","DL"),("ahmedabad","GJ"),("pune","MH"),("jaipur","RJ")]
tiers = ["gold","GOLD","Gold",None]
channels = ["mobile_app","WEB","Partner_API"]
currencies = ["inr","INR","usd","USD"]
methods = ["Credit Card","Debit Card","UPI","COD"]
statuses = ["SUCCESS","success","failed","PENDING"]
event_types = ["ORDER_PLACED","order_cancelled","Add_To_Cart","CHECKOUT","page_view"]
brands = ["samsung","apple","nike","lg","sony","adidas"]
categories = ["ELECTRONICS","electronics","Apparel","HOME GOODS"]
subcats = ["televisions","phones","shoes","kitchen","laptops"]
sources = ["mobile","web","partner_api"]

products_master=[]
for i in range(1,401):
    products_master.append(f"P-{i:03d}")

def money(v):
    return f"${v:,.2f}"

def rand_date():
    base=datetime(2024,1,1)
    d=base+timedelta(days=random.randint(0,180),hours=random.randint(0,23),minutes=random.randint(0,59))
    return d

with open("products.csv","w",newline="",encoding="utf-8") as f:
    w=csv.writer(f)
    w.writerow(["data","_loaded_at"])
    for i in range(NUM_PRODUCTS):
        pid=random.choice(products_master)
        price=round(random.uniform(50,2000),2)
        cost=round(price*random.uniform(0.5,0.9),2)
        qty=random.randint(0,100)
        reorder=random.randint(5,20)
        obj={
            "product_id":pid,
            "name":f" {random.choice(brands).title()} {random.choice(subcats).title()} ",
            "category":random.choice(categories),
            "sub_category":random.choice(subcats),
            "brand":random.choice(brands),
            "is_available":random.choice(["1","0","YES","NO","true","false"]),
            "tags":["smart","4K","OLED"] if random.random()>0.5 else ["sale","popular"],
            "specs":{"weight_kg":str(round(random.uniform(0.2,20),1)),
                     "warranty_yr":str(random.randint(1,5))},
            "pricing":{"cost_price":cost,"list_price":price,"currency":"USD"},
            "stock":{"qty_on_hand":str(qty),
                     "reorder_lvl":str(reorder),
                     "warehouse":random.choice(["WH-WEST","WH-EAST","WH-NORTH"])}
        }
        w.writerow([json.dumps(obj),rand_date().isoformat(sep=" "),])

with open("orders.csv","w",newline="",encoding="utf-8") as f:
    w=csv.writer(f)
    w.writerow(["data","_loaded_at","_source"])
    event_ids=[]
    for i in range(NUM_ORDERS):
        if i>0 and random.random()<0.08:
            event_id=random.choice(event_ids)
        else:
            event_id=f"EVT-20240315-{i:05d}"
            event_ids.append(event_id)

        cust=random.randint(1,700)
        fname=random.choice(first_names)
        lname=random.choice(last_names)
        city,state=random.choice(cities)
        order_dt=rand_date()
        item_count=random.randint(1,5)
        items=[]
        total=0
        for _ in range(item_count):
            p=random.choice(products_master)
            qty=random.choice([None,0,1,2,3,4,5])
            price=round(random.uniform(20,1000),2)
            disc=random.choice([0,5,10,15,20,30,50,80])
            q=qty if qty else 0
            total+=q*price
            items.append({
                "product_id":p,
                "qty":None if qty is None else str(qty),
                "unit_price": money(price) if random.random()>0.5 else f"{price:.2f}",
                "discount_pct":disc
            })
        obj={
            "event_id":event_id,
            "event_type":random.choice(event_types),
            "occurred_at":order_dt.strftime("%d/%m/%Y %H:%M:%S"),
            "customer":{
                "id":f" C-{cust:05d} ",
                "name":f"{fname} {lname}",
                "email":f"{fname}.{lname}@GMAIL.COM",
                "phone":"(+91) 98765-43210",
                "tier":random.choice(tiers),
                "address":{
                    "city":city,
                    "state":state,
                    "country":"IN"
                }
            },
            "order":{
                "order_id":f"ORD-2024-{i:05d}",
                "channel":random.choice(channels),
                "placed_at":order_dt.strftime("%Y-%m-%d"),
                "currency":random.choice(currencies),
                "total_amount":money(total),
                "items":items,
                "payment":{
                    "method":random.choice(methods),
                    "status":random.choice(statuses),
                    "gateway":random.choice(["Razorpay","Stripe","PayU"])
                }
            },
            "metadata":{
                "app_version":f"3.{random.randint(0,5)}.{random.randint(0,9)}",
                "is_test_event":random.choice(["false","false","false","true"])
            }
        }
        w.writerow([json.dumps(obj),order_dt.isoformat(sep=" "),random.choice(sources)])

print("Generated orders.csv and products.csv")