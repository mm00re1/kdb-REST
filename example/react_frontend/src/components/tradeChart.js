import React from 'react';
import ApexCharts from 'react-apexcharts';

function parseTimeToTimestamp(timeStr) {
  const today = new Date();
  const [hours, minutes, secondsMillis] = timeStr.split(':');
  const [seconds, millis] = secondsMillis.split('.');

  const date = new Date(
    today.getFullYear(),
    today.getMonth(),
    today.getDate(),
    Number(hours),
    Number(minutes),
    Number(seconds),
    Number(millis.slice(0, 3)) // slice to 3 digits (milliseconds)
  );

  return date.getTime(); // timestamp in ms
}

const TradeChart = ({ data }) => {
  if (!data || data.length === 0) {
    return <div>No data available</div>;
  }

  const series = [{
    name: 'Price',
    data: data.map(item => ({
      x: parseTimeToTimestamp(item.time),
      y: item.price
    }))
  }];

  // Define chart options
  const options = {
    chart: {
      type: 'line',
      height: 350
    },
    xaxis: {
      type: 'datetime', // Change to 'datetime' to handle date-time values
      tickAmount: 10, // de-clutter the x axis
      labels: {
        formatter: function(value) {
          return new Date(value).toLocaleTimeString(); // Formats the x-axis labels as time strings
        }
      }
    },
    yaxis: {
        labels: {
          formatter: function(value) {
            return value.toFixed(2); // Round to 2 decimal places
          }
        },
    },

    tooltip: {
      x: {
        format: 'HH:mm:ss'
      }
    },
    stroke: {
      curve: 'straight'
    },
  };

  return (
    <div style={{marginLeft: '5%', marginRight: '20%'}}>
      <ApexCharts options={options} series={series} type="line" height={350} />
    </div>
  );
};

export default TradeChart;
