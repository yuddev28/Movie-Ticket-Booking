import React, { useState, useEffect } from 'react';
import movieService from '../../service/movieService';
import genreService from '../../service/genreService';
import Modal from '../../components/common/Modal';
import { useToast } from '../../context/ToastContext';

// Helper Mapping Trạng Thái Phim sang Tiếng Việt
export const MOVIE_STATUS_MAP = {
  NOW_SHOWING: { label: 'ĐANG CHIẾU', class: 'bg-emerald-950 text-emerald-400 border-emerald-800' },
  COMING_SOON: { label: 'SẮP CHIẾU', class: 'bg-amber-950 text-amber-400 border-amber-800' },
  END_SHOWING: { label: 'NGỪNG CHIẾU', class: 'bg-slate-800 text-slate-400 border-slate-700' },
};

export default function AdminMovies() {
  const { toast } = useToast();
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [data, setData] = useState({ content: [], totalPages: 0 });
  const [genres, setGenres] = useState([]);
  const [loading, setLoading] = useState(false);

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingMovie, setEditingMovie] = useState(null);
  const [formData, setFormData] = useState({
    name: '',
    directorName: '',
    actorsName: '',
    description: '',
    duration: 120,
    country: '',
    imageUrl: '',
    movieStatus: 'NOW_SHOWING',
    showAt: '',
    genreIds: [],
  });

  const fetchMovies = async () => {
    setLoading(true);
    try {
      const res = await movieService.filter(search, page, 10);
      if (res && Array.isArray(res.content)) {
        setData({
          content: res.content,
          totalPages: res.totalPages || 1,
          totalElements: res.totalElements != null ? res.totalElements : res.content.length,
          pageNumber: res.pageNumber || page,
        });
      } else if (Array.isArray(res)) {
        setData({ content: res, totalPages: 1, totalElements: res.length, pageNumber: 1 });
      } else {
        setData({ content: [], totalPages: 0, totalElements: 0, pageNumber: 1 });
      }
    } catch (err) {
      console.error(err);
      setData({ content: [], totalPages: 0, totalElements: 0, pageNumber: 1 });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMovies();
  }, [search, page]);

  useEffect(() => {
    const fetchGenres = async () => {
      try {
        const list = await genreService.getAll();
        setGenres(Array.isArray(list) ? list : []);
      } catch (err) {
        console.error(err);
      }
    };
    fetchGenres();
  }, []);

  const handleOpenAdd = () => {
    setEditingMovie(null);
    setFormData({
      name: '',
      directorName: '',
      actorsName: '',
      description: '',
      duration: 120,
      country: '',
      imageUrl: '',
      movieStatus: 'NOW_SHOWING',
      showAt: '',
      genreIds: [],
    });
    setIsModalOpen(true);
  };

  const handleOpenEdit = (m) => {
    setEditingMovie(m);
    const currentStatus = m.movieStatus || m.status || 'NOW_SHOWING';
    setFormData({
      name: m.name || '',
      directorName: m.directorName || '',
      actorsName: m.actorsName || '',
      description: m.description || '',
      duration: m.duration || 120,
      country: m.country || '',
      imageUrl: m.imageUrl || '',
      movieStatus: currentStatus,
      showAt: m.showAt ? m.showAt.split('T')[0] : '',
      genreIds: m.genres ? genres.filter((g) => m.genres.includes(g.name)).map((g) => g.id) : [],
    });
    setIsModalOpen(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      // Đảm bảo showAt có đủ định dạng yyyy-MM-ddTHH:mm:ss nếu có giá trị
      let formattedShowAt = formData.showAt;
      if (formattedShowAt && !formattedShowAt.includes('T')) {
        formattedShowAt = `${formattedShowAt}T00:00:00`;
      }

      if (editingMovie) {
        // Cấu trúc chuẩn theo UpdateMovieRequest trong Backend:
        // { id, name, directorName, actorsName, description, duration, country, imageUrl, movieStatus, showAt }
        const updatePayload = {
          id: editingMovie.id,
          name: formData.name,
          directorName: formData.directorName,
          actorsName: formData.actorsName,
          description: formData.description,
          duration: Number(formData.duration),
          country: formData.country,
          imageUrl: formData.imageUrl,
          movieStatus: formData.movieStatus,
          showAt: formattedShowAt || null,
        };
        await movieService.edit(editingMovie.id, updatePayload);
        toast.success('Cập nhật phim thành công!');
      } else {
        const createPayload = {
          name: formData.name,
          directorName: formData.directorName,
          actorsName: formData.actorsName,
          description: formData.description,
          duration: Number(formData.duration),
          country: formData.country,
          imageUrl: formData.imageUrl,
          movieStatus: formData.movieStatus,
          showAt: formattedShowAt || null,
          genres: formData.genreIds || [],
        };
        await movieService.add(createPayload);
        toast.success('Thêm phim mới thành công!');
      }
      setIsModalOpen(false);
      fetchMovies();
    } catch (err) {
      toast.error(err.message || 'Thao tác thất bại');
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Bạn có chắc chắn muốn xóa phim này không? Các suất chiếu liên quan cũng có thể bị ảnh hưởng.')) {
      try {
        await movieService.delete(id);
        toast.success('Xóa phim thành công!');
        fetchMovies();
      } catch (err) {
        toast.error(err.message || 'Xóa phim thất bại');
      }
    }
  };

  const movieList = Array.isArray(data?.content) ? data.content : [];

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 border-b border-slate-800 pb-4">
        <div>
          <h1 className="text-2xl font-extrabold text-white">Quản Lý Phim</h1>
          <p className="text-xs text-slate-400">Danh sách phim điện ảnh đang và sắp chiếu</p>
        </div>
        <div className="flex items-center gap-3 w-full sm:w-auto">
          <input
            type="text"
            placeholder="Tìm kiếm phim..."
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1); }}
            className="bg-slate-900 border border-slate-700 rounded-xl px-4 py-2 text-sm text-white focus:outline-none focus:border-red-500 w-full sm:w-64"
          />
          <button
            onClick={handleOpenAdd}
            className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white font-bold rounded-xl text-sm transition-all shrink-0 shadow-lg shadow-red-900/30"
          >
            + Thêm Phim
          </button>
        </div>
      </div>

      {loading ? (
        <p className="text-slate-400 text-sm">Đang tải danh sách phim...</p>
      ) : (
        <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
          <table className="w-full text-left text-sm text-slate-300">
            <thead className="bg-slate-800 text-slate-200 text-xs uppercase font-bold">
              <tr>
                <th className="p-4">ID</th>
                <th className="p-4">Poster</th>
                <th className="p-4">Tên Phim</th>
                <th className="p-4">Thời Lượng</th>
                <th className="p-4">Đánh Giá</th>
                <th className="p-4">Trạng Thái</th>
                <th className="p-4 text-right">Hành Động</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800">
              {movieList.length === 0 ? (
                <tr>
                  <td colSpan="7" className="p-6 text-center text-slate-500">
                    Không tìm thấy phim phù hợp
                  </td>
                </tr>
              ) : (
                movieList.map((m) => {
                  const statusKey = m.movieStatus || m.status;
                  const statusInfo = MOVIE_STATUS_MAP[statusKey] || { label: statusKey || 'CHƯA RÕ', class: 'bg-slate-800 text-slate-300 border-slate-700' };
                  return (
                    <tr key={m.id} className="hover:bg-slate-800/50 transition-colors">
                      <td className="p-4 font-mono font-bold text-red-400">#{m.id}</td>
                      <td className="p-4">
                        <img src={m.imageUrl} alt={m.name} className="w-10 h-14 object-cover rounded shadow" />
                      </td>
                      <td className="p-4 font-bold text-white text-base">{m.name}</td>
                      <td className="p-4 font-semibold text-slate-300">{m.duration} phút</td>
                      <td className="p-4 font-bold text-amber-400">★ {m.rating || 9.0}</td>
                      <td className="p-4">
                        <span className={`px-2.5 py-1 rounded text-xs font-bold border ${statusInfo.class}`}>
                          {statusInfo.label}
                        </span>
                      </td>
                      <td className="p-4 text-right space-x-2">
                        <button
                          onClick={() => handleOpenEdit(m)}
                          className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg text-xs font-semibold border border-slate-700 transition-all"
                        >
                          Chỉnh Sửa
                        </button>
                        <button
                          onClick={() => handleDelete(m.id)}
                          className="px-3 py-1.5 bg-red-950/50 hover:bg-red-900/80 text-red-400 rounded-lg text-xs font-semibold border border-red-900/50 transition-all"
                        >
                          Xóa
                        </button>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>

          {data.totalPages > 0 && (
            <div className="flex flex-col sm:flex-row justify-between items-center p-4 border-t border-slate-800 gap-3 text-xs text-slate-400">
              <div>
                Hiển thị <span className="font-bold text-white">{movieList.length}</span> / <span className="font-bold text-white">{data.totalElements || movieList.length}</span> phim
              </div>
              <div className="flex items-center gap-2">
                <button
                  disabled={page <= 1 || loading}
                  onClick={() => setPage((p) => Math.max(p - 1, 1))}
                  className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg disabled:opacity-40 transition-colors font-semibold border border-slate-700"
                >
                  ◀ Trang trước
                </button>
                <span className="px-3 font-semibold text-slate-200">
                  Trang <span className="text-red-400 font-bold">{page}</span> / {data.totalPages || 1}
                </span>
                <button
                  disabled={page >= data.totalPages || loading}
                  onClick={() => setPage((p) => p + 1)}
                  className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg disabled:opacity-40 transition-colors font-semibold border border-slate-700"
                >
                  Trang sau ▶
                </button>
              </div>
            </div>
          )}
        </div>
      )}

      {/* MODAL THÊM / SỬA PHIM VỚI STATUS VIỆT HÓA */}
      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={editingMovie ? 'Chỉnh Sửa Phim' : 'Thêm Phim Mới'}>
        <form onSubmit={handleSubmit} className="space-y-4 text-sm text-slate-200">
          <div>
            <label className="block text-xs font-semibold mb-1">
              Tên Phim <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              required
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2 text-white focus:outline-none focus:border-red-500"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold mb-1">
                Đạo Diễn <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                required
                placeholder="vd: Christopher Nolan"
                value={formData.directorName}
                onChange={(e) => setFormData({ ...formData, directorName: e.target.value })}
                className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2 text-white focus:outline-none focus:border-red-500"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold mb-1">
                Diễn Viên <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                required
                placeholder="vd: Leonardo DiCaprio, ..."
                value={formData.actorsName}
                onChange={(e) => setFormData({ ...formData, actorsName: e.target.value })}
                className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2 text-white focus:outline-none focus:border-red-500"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold mb-1">
                Thời Lượng (Phút) <span className="text-red-500">*</span>
              </label>
              <input
                type="number"
                required
                min="1"
                value={formData.duration}
                onChange={(e) => setFormData({ ...formData, duration: parseInt(e.target.value, 10) || 0 })}
                className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2 text-white focus:outline-none focus:border-red-500"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold mb-1">
                Quốc Gia <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                required
                placeholder="vd: Mỹ, Hàn Quốc, Việt Nam"
                value={formData.country}
                onChange={(e) => setFormData({ ...formData, country: e.target.value })}
                className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2 text-white focus:outline-none focus:border-red-500"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold mb-1">Trạng Thái Chiếu</label>
              <select
                value={formData.movieStatus}
                onChange={(e) => setFormData({ ...formData, movieStatus: e.target.value })}
                className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2 text-white focus:outline-none focus:border-red-500"
              >
                <option value="NOW_SHOWING">🎬 ĐANG CHIẾU</option>
                <option value="COMING_SOON">🌟 SẮP CHIẾU</option>
                <option value="STOPPED_SHOWING">🚫 NGỪNG CHIẾU</option>
              </select>
            </div>
            <div>
              <label className="block text-xs font-semibold mb-1">Ngày Chiếu (Show At)</label>
              <input
                type="date"
                value={formData.showAt}
                onChange={(e) => setFormData({ ...formData, showAt: e.target.value })}
                className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2 text-white focus:outline-none focus:border-red-500"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold mb-1">
              Poster URL (Hình ảnh) <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              required
              placeholder="https://example.com/poster.jpg"
              value={formData.imageUrl}
              onChange={(e) => setFormData({ ...formData, imageUrl: e.target.value })}
              className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2 text-white focus:outline-none focus:border-red-500"
            />
          </div>

          {!editingMovie && genres.length > 0 && (
            <div>
              <label className="block text-xs font-semibold mb-1">Thể Loại Phim</label>
              <div className="flex flex-wrap gap-2 max-h-32 overflow-y-auto p-2 bg-slate-950 border border-slate-800 rounded-xl">
                {genres.map((g) => {
                  const isChecked = formData.genreIds?.includes(g.id);
                  return (
                    <label
                      key={g.id}
                      className={`px-2.5 py-1 rounded-lg text-xs cursor-pointer border transition-colors ${
                        isChecked
                          ? 'bg-red-950/80 border-red-600 text-red-200'
                          : 'bg-slate-900 border-slate-800 text-slate-400 hover:border-slate-700'
                      }`}
                    >
                      <input
                        type="checkbox"
                        className="hidden"
                        checked={isChecked}
                        onChange={(e) => {
                          const newIds = e.target.checked
                            ? [...(formData.genreIds || []), g.id]
                            : (formData.genreIds || []).filter((id) => id !== g.id);
                          setFormData({ ...formData, genreIds: newIds });
                        }}
                      />
                      {g.name}
                    </label>
                  );
                })}
              </div>
            </div>
          )}

          <div>
            <label className="block text-xs font-semibold mb-1">Mô Tả Phim</label>
            <textarea
              rows="3"
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              placeholder="Nội dung tóm tắt phim..."
              className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2 text-white focus:outline-none focus:border-red-500"
            />
          </div>

          <div className="flex justify-end gap-3 pt-4 border-t border-slate-800">
            <button
              type="button"
              onClick={() => setIsModalOpen(false)}
              className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs font-semibold"
            >
              Hủy
            </button>
            <button
              type="submit"
              className="px-5 py-2 bg-red-600 hover:bg-red-700 text-white rounded-xl text-xs font-bold shadow"
            >
              Lưu Phim
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
