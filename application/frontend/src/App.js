import React, { useEffect, useState } from 'react';
import axios from 'axios';

function App() {
  const [health, setHealth] = useState('');
  const [deployments, setDeployments] = useState([]);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(1);

  const apiUrl = ''; // Nginx proxy

  const fetchDeployments = (pageNumber = 0) => {
    axios
      .get(`${apiUrl}/api/deployments?page=${pageNumber}&size=20`)
      .then(res => {
        setDeployments(res.data.content);
        setPage(res.data.number);
        setTotalPages(res.data.totalPages);
      })
      .catch(err => console.error('Error fetching deployments:', err));
  };

  useEffect(() => {
    // Function to refresh both health and deployments
    const refreshDashboard = () => {
      // Fetch backend health
      axios.get(`${apiUrl}/api/health`)
        .then(res => setHealth(res.data.status))
        .catch(err => setHealth('Error: ' + err.message));

      // Fetch current page of deployments
      fetchDeployments(page);
    };

    // Initial load
    refreshDashboard();

    // Poll every 5 seconds
    const interval = setInterval(refreshDashboard, 5000);

    return () => clearInterval(interval);
  }, [page]);

  return (
    <div className="min-h-screen bg-gray-100 p-8 font-sans">
      <div className="max-w-6xl mx-auto bg-white shadow-md rounded-lg p-6">
        <h1 className="text-3xl font-bold mb-4 text-blue-600">DevOps Dashboard</h1>
        <p className="text-lg mb-6">
          <span className="font-semibold">Backend Health:</span>{" "}
          <span className={health === 'OK' ? 'text-green-600' : 'text-red-600'}>
            {health}
          </span>
        </p>

        <h2 className="text-2xl font-semibold mb-4 text-gray-700">Deployments</h2>

        {deployments.length === 0 ? (
          <p className="text-gray-500">No deployments found</p>
        ) : (
          <>
            <div className="overflow-x-auto">
              <table className="w-full table-auto border-collapse border border-gray-300">
                <thead>
                  <tr className="bg-gray-200">
                    <th className="border border-gray-300 px-4 py-2 text-left">ID</th>
                    <th className="border border-gray-300 px-4 py-2 text-left">Version</th>
                    <th className="border border-gray-300 px-4 py-2 text-left">Environment</th>
                    <th className="border border-gray-300 px-4 py-2 text-left">Success</th>
                    <th className="border border-gray-300 px-4 py-2 text-left">Notes</th>
                    <th className="border border-gray-300 px-4 py-2 text-left">Created At</th>
                  </tr>
                </thead>
                <tbody>
                  {deployments.map(d => (
                    <tr
                      key={d.id}
                      className={`hover:bg-gray-100 ${!d.success ? 'bg-red-100' : ''}`}
                    >
                      <td className="border border-gray-300 px-4 py-2">{d.id}</td>
                      <td className="border border-gray-300 px-4 py-2">{d.version}</td>
                      <td className="border border-gray-300 px-4 py-2">{d.environment}</td>
                      <td className={`border border-gray-300 px-4 py-2 font-semibold ${d.success ? 'text-green-600' : 'text-red-600'}`}>
                        {d.success ? 'Yes' : 'No'}
                      </td>
                      <td className="border border-gray-300 px-4 py-2">{d.notes || '-'}</td>
                      <td className="border border-gray-300 px-4 py-2">{new Date(d.createdAt).toLocaleString()}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div className="flex justify-center items-center mt-6 space-x-4">
              <button
                onClick={() => fetchDeployments(page - 1)}
                disabled={page === 0}
                className="px-4 py-2 bg-blue-500 text-white rounded disabled:bg-gray-300"
              >
                Previous
              </button>
              <span className="text-gray-700 font-medium">
                Page {page + 1} of {totalPages}
              </span>
              <button
                onClick={() => fetchDeployments(page + 1)}
                disabled={page + 1 >= totalPages}
                className="px-4 py-2 bg-blue-500 text-white rounded disabled:bg-gray-300"
              >
                Next
              </button>
            </div>
          </>
        )}
      </div>

      {/* Alert for any failed deployments */}
      {deployments.some(d => !d.success) && (
        <div className="fixed top-4 right-4 bg-red-500 text-white p-4 rounded shadow-lg animate-pulse z-50">
          ⚠️ There are failed deployments!
        </div>
      )}
    </div>
  );
}

export default App;
