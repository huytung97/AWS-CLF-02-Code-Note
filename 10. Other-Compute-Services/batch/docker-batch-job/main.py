import sys
import time
import logging

import pandas as pd
from tabulate import tabulate

# Configure logging
logging.basicConfig(
    level=logging.INFO,                      # Set the log level
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),  # Log to stdout
    ]
)

logging.getLogger().handlers[0].flush = sys.stdout.flush

logging.info('start job')

df = pd.read_parquet('flights-1m.parquet')

df['FL_DATE'] = pd.to_datetime(df['FL_DATE'], format='%Y-%m-%d')

df['FL_MONTH'] = df['FL_DATE'].dt.strftime('%Y-%m')

result = df.groupby('FL_MONTH').agg({
    'DEP_DELAY': ['max', 'min'],
    'AIR_TIME': ['mean']
})

logging.info('wait job')

# simulate large batch job - 60 seconds :)))
time.sleep(60)

logging.info('finish job')

print(tabulate(result, headers='keys', tablefmt='pretty'))