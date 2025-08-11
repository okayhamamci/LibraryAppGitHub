namespace LibraryApp.Models.DTOs
{
    public class BorrowRecordDTO
    {
        public int Id { get; set; }
        public string Title { get; set; } = "";
        public string Author { get; set; } = "";
        public DateTime BorrowedAt { get; set; }
        public DateTime? ReturnedAt { get; set; }
    }
}
