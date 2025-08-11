﻿namespace LibraryApp.Models.DTOs
{
    public class registerRequestDTO
    {
        public string Username { get; set; }
        public string Email { get; set; }
        public string Password { get; set; }
        public registerRequestDTO(string username, string email, string password)
        {
            Username = username;
            Email = email;
            Password = password;
        }
    }
}
